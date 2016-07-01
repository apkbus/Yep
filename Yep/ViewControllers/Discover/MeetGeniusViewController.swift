//
//  MeetGeniusViewController.swift
//  Yep
//
//  Created by NIX on 16/5/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking

class MeetGeniusViewController: UIViewController {

    var showGeniusInterviewAction: (() -> Void)?

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableHeaderView = MeetGeniusShowView(frame: CGRect(x: 0, y: 0, width: 100, height: 180))
            tableView.tableFooterView = UIView()

            tableView.rowHeight = 90

            tableView.registerNibOf(GeniusInterviewCell)
            tableView.registerNibOf(LoadMoreTableViewCell)
        }
    }

    var geniusInterviews: [GeniusInterview] = []

    private var canLoadMore: Bool = false
    private var isFetchingGeniusInterviews: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        println("tableView.tableHeaderView: \(tableView.tableHeaderView)")

        updateGeniusInterviews()
    }

    private enum UpdateGeniusInterviewsMode {
        case Top
        case LoadMore
    }

    private func updateGeniusInterviews(mode mode: UpdateGeniusInterviewsMode = .Top, finish: (() -> Void)? = nil) {

        if isFetchingGeniusInterviews {
            finish?()
            return
        }

        isFetchingGeniusInterviews = true

        let maxNumber: Int?
        switch mode {
        case .Top:
            canLoadMore = true
            maxNumber = nil
        case .LoadMore:
            maxNumber = geniusInterviews.last?.number
        }

        let failureHandler: FailureHandler = { reason, errorMessage in

            SafeDispatch.async { [weak self] in

                self?.isFetchingGeniusInterviews = false

                finish?()
            }

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
        }

        geniusInterviewsWithCount(10, afterNumber: maxNumber, failureHandler: failureHandler, completion: { [weak self] geniusInterviews in

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                let newGeniusInterviews = geniusInterviews
                let oldGeniusInterviews = strongSelf.geniusInterviews

                var wayToUpdate: UITableView.WayToUpdate = .None

                if oldGeniusInterviews.isEmpty {
                    wayToUpdate = .ReloadData
                }

                switch mode {

                case .Top:
                    strongSelf.geniusInterviews = newGeniusInterviews

                    wayToUpdate = .ReloadData

                case .LoadMore:
                    let oldGeniusInterviewsCount = oldGeniusInterviews.count

                    let oldGeniusInterviewNumberSet = Set<Int>(oldGeniusInterviews.map({ $0.number }))
                    var realNewGeniusInterviews = [GeniusInterview]()
                    for geniusInterview in newGeniusInterviews {
                        if !oldGeniusInterviewNumberSet.contains(geniusInterview.number) {
                            realNewGeniusInterviews.append(geniusInterview)
                        }
                    }
                    strongSelf.geniusInterviews += realNewGeniusInterviews

                    let newGeniusInterviewsCount = strongSelf.geniusInterviews.count

                    let indexPaths = Array(oldGeniusInterviewsCount..<newGeniusInterviewsCount).map({ NSIndexPath(forRow: $0, inSection: Section.GeniusInterview.rawValue) })
                    if !indexPaths.isEmpty {
                        wayToUpdate = .Insert(indexPaths)
                    }
                }

                wayToUpdate.performWithTableView(strongSelf.tableView)

                self?.isFetchingGeniusInterviews = false

                finish?()
            }
        })
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension MeetGeniusViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {
        case GeniusInterview
        case LoadMore
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            return geniusInterviews.count

        case .LoadMore:
            return geniusInterviews.isEmpty ? 0 : 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            let cell: GeniusInterviewCell = tableView.dequeueReusableCell()
            let geniusInterview = geniusInterviews[indexPath.row]
            cell.configure(withGeniusInterview: geniusInterview)
            return cell

        case .LoadMore:
            let cell: LoadMoreTableViewCell = tableView.dequeueReusableCell()
            cell.isLoading = true
            return cell
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            break

        case .LoadMore:
            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            guard canLoadMore else {
                cell.isLoading = false
                break
            }

            println("load more feeds")

            if !cell.isLoading {
                cell.isLoading = true
            }

            updateGeniusInterviews(mode: .LoadMore, finish: {
                delay(0.5) { [weak cell] in
                    cell?.isLoading = false
                }
            })
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            showGeniusInterviewAction?()

        case .LoadMore:
            break
        }
    }
}

