<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Help.ascx.cs" Inherits="QProcess.Controls.Shared.Help" %>
<style>
    .back-to-top-container {
        position: fixed;
        bottom: 7%;
        left: 1%;
        z-index: 9;
        text-decoration: none !important;
        font-weight: bold;
    }

    .back-to-top {
        color: white;
        padding: 10px;
        border-radius: 5px;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.3s, visibility 0.3s;
        text-decoration: none !important;
    }

        .back-to-top:hover, .back-to-top a {
            text-decoration: none !important;
        }

    body:hover .back-to-top {
        opacity: 1;
        visibility: visible;
        text-decoration: none !important;
    }
</style>
<div id="top"></div>
<!-- ============================================================
						MENU 
		============================================================ -->
<div style="padding-right: 5px; padding-left: 5px; padding-bottom: 5px; padding-top: 5px">
    <h4>For assistance, please email <a href="mailto:it@acmewidget.com">it@acmewidget.com</a>.</h4>
    <div class="table-of-contents">
        <h2>GLOSSARY OF TERMS</h2>
        <ol>
            <li><a href="#g1">Task</a></li>
            <li><a href="#g2">Checklist</a></li>
            <li><a href="#g3">Checklist Item</a></li>
            <li><a href="#g4">Instance</a></li>
            <li><a href="#g5">Upcoming Checklist / Upcoming Task</a></li>
            <li><a href="#g6">Active Checklist / Active Task</a></li>
            <li><a href="#g7">Controller</a></li>
            <li><a href="#g8">Assignee</a></li>
            <li><a href="#g9">Alert</a></li>
            <li><a href="#g10">Reminder</a></li>
            <li><a href="#g11">Template</a></li>
            <li><a href="#g12">Group</a></li>
            <li><a href="#g13">Supervisor</a></li>
            <li><a href="#g14">Interested Party</a></li>
            <li><a href="#g15">Priority List</a></li>
            <li><a href="#g16">Supervisor Controlled Task</a></li>
            <li><a href="#g17">Soft Deadline</a></li>
            <li><a href="#g18">Change Request</a></li>
        </ol>
        <h2>HOW TO USE <%= QProcess.Configuration.AppSettings.AppName.ToUpperInvariant()%></h2>
        <ol>
            <li><a href="#1">My Tasks</a>
                <ol>
                    <li><a href="#1.1">Task Type Filter</a></li>
                    <li><a href="#1.2">Date Range Filter</a></li>
                    <li><a href="#1.3">Checklist Header</a></li>
                    <li><a href="#1.4">Expanding</a></li>
                    <li><a href="#1.5">Exporting</a></li>
                    <li><a href="#1.6">Completing a step</a></li>
                    <li><a href="#1.7">N/A a Checklist</a></li>
                    <li><a href="#1.8">Exporting a Checklist</a></li>
                    <li><a href="#1.9">Completing a Checklist</a></li>
                    <li><a href="#1.10">Get Task Extension</a></li>
                    <li><a href="#1.11">My Tasks Search</a></li>
                    <li><a href="#1.12">Task History</a></li>
                </ol>
            </li>
            <li><a href="#2">The Calendar</a>
                <ol>
                    <li><a href="#2.1">Selecting a Day</a></li>
                    <li><a href="#2.2">Using the Key</a></li>
                    <li><a href="#2.3">Filtering</a></li>
                    <li><a href="#2.4">Viewing a Checklist</a></li>
                    <li><a href="#2.5">Get Task Extension</a></li>
                    <li><a href="#2.6">Calendar Search</a></li>
                    <li><a href="#2.7">Calendar Email Summary</a></li>
                </ol>
            </li>
            <li><a href="#3">Manage Tasks</a>
                <ol>
                    <li><a href="#3.1">Filters</a></li>
                    <li><a href="#3.2">Folder Structure</a>
                        <ol>
                            <li><a href="#3.2.1">Default Setup</a></li>
                            <li><a href="#3.2.2">Adding Sub Folders</a></li>
                            <li><a href="#3.2.3">Renaming Folders</a></li>
                            <li><a href="#3.2.4">Deleting Folders</a></li>
                            <li><a href="#3.2.5">Moving Tasks/Folders</a></li>
                        </ol>
                    </li>
                    <li><a href="#3.3">Deleting</a></li>
                    <li><a href="#3.4">Expanding</a></li>
                    <li><a href="#3.5">Copying</a></li>
                    <li><a href="#3.6">Naming</a></li>
                    <li><a href="#3.7">Controllers</a></li>
                    <li><a href="#3.8">Items</a></li>
                    <li><a href="#3.9">Assignments</a>
                        <ol>
                            <li><a href="#3.9.1">Expanding</a></li>
                            <li><a href="#3.9.2">Copying</a></li>
                            <li><a href="#3.9.3">Assigned To</a></li>
                            <li><a href="#3.9.4">Status Reports</a></li>
                            <li><a href="#3.9.5">Scheduling</a></li>
                            <li><a href="#3.9.6">Alerts/Reminders</a></li>
                            <li><a href="#3.9.7">Working on Now</a></li>
                        </ol>
                    </li>
                    <li><a href="#3.10">Templates</a></li>
                    <li><a href="#3.11">Change Requests</a></li>
                    <li><a href="#3.12">Export to Excel</a></li>
                </ol>
            </li>
            <li><a href="#4">New Tasks</a>
                <ol>
                    <li><a href="#4.1">Default or Customized?</a></li>
                    <li><a href="#4.2">Default Task Creation</a></li>
                    <li><a href="#4.3">Customized Task Creation</a></li>
                    <li><a href="#4.4">Creating Tasks from Email</a></li>
                    <li><a href="#4.5">Create a task from template</a></li>
                </ol>
            </li>
            <li><a href="#5">Change Requests</a>
                <ol>
                    <li><a href="#5.1">Changes to Tasks I Control</a></li>
                    <li><a href="#5.2">My Requests to Others</a></li>
                    <li><a href="#5.3">Change Request Emails</a></li>
                </ol>
            </li>
            <li><a href="#6">Reports</a>
                <ol>
                    <li><a href="#6.1">Overdue</a></li>
                    <li><a href="#6.2">History</a></li>
                </ol>
            </li>
            <li><a href="#7">Groups</a>
                <ol>
                    <li><a href="#7.1">Adding Groups</a></li>
                    <li><a href="#7.2">Editing/Viewing Groups</a></li>
                    <li><a href="#7.3">Removing Groups</a></li>
                </ol>
            </li>
            <li><a href="#8">Task Summary</a>
                <ol>
                    <li><a href="#8.1">Assigned To Me - No Status</a></li>
                    <li><a href="#8.2">Assigned To Me - With Status</a></li>
                    <li><a href="#8.3">Assigned To Others</a></li>
                    <li><a href="#8.4">Viewing Checklists</a></li>
                    <li><a href="#8.5">Moving Tasks To Status Reports</a></li>
                </ol>
            </li>
            <li><a href="#9">My Status</a>
                <ol>
                    <li><a href="#9.1">Supervisors</a></li>
                    <li><a href="#9.2">Sections</a></li>
                    <li><a href="#9.3">Adding A Task</a></li>
                    <li><a href="#9.4">Altering a Task</a></li>
                    <li><a href="#9.5">Completing Tasks</a></li>
                    <li><a href="#9.6">Moving Tasks</a></li>
                    <li><a href="#9.7">Removing Tasks</a></li>
                    <li><a href="#9.8">Managing Reports</a></li>
                    <li><a href="#9.9">Viewing the Archive</a></li>
                    <li><a href="#9.10">Exporting</a></li>
                    <li><a href="#9.11">Emails</a></li>
                    <li><a href="#9.12">Emailing Comments</a>
                        <ol>
                            <li><a href="#9.12.1">Showing task details when emailing all comments</a></li>
                        </ol>
                    </li>
                    <li><a href="#9.13">Controllers</a></li>
                    <li><a href="#9.14">Highlighting/View Deleted</a></li>
                    <li><a href="#9.15">Hide Tasks Without Comments</a></li>
                    <li><a href="#9.16">Show Tasks Assigned To Specific Users</a></li>
                    <li><a href="#9.17">Timeline</a></li>
                    <li><a href="#9.18">Toggle Assignees</a></li>
                    <li><a href="#9.19">Printing</a></li>
                    <li><a href="#9.20">Searching</a></li>
                    <li><a href="#9.21">Adding Links to Comments</a></li>
                    <li><a href="#9.22">Bulk Update</a></li>
                    <li><a href="#9.23">Response Requested</a></li>
                    <li><a href="#9.24">Switching Between Reports</a></li>
                    <li><a href="#9.25">Reassign a Task</a></li>
                    <li><a href="#9.26">My Status Search</a></li>
                </ol>
            </li>
            <li><a href="#10">My Inbox</a>
                <ol>
                    <li><a href="#10.1">The Inbox</a></li>
                    <li><a href="#10.2">Adding Comments</a></li>
                    <li><a href="#10.3">Highlighting/View Deleted</a></li>
                    <li><a href="#10.4">Hide Tasks Without Comments</a></li>
                    <li><a href="#10.5">Show Tasks Assigned To Specific Users</a></li>
                    <li><a href="#10.6">Mark a Status Report Read</a></li>
                    <li><a href="#10.7">Emailing Comments</a></li>
                    <li><a href="#10.8">Inbox Navigation</a></li>
                    <li><a href="#10.9">Take Control</a></li>
                    <li><a href="#10.10">Manage Emails</a></li>
                    <li><a href="#10.11">My Inbox Search</a></li>
                    <li><a href="#10.12">Supervisor Dashboard</a>
                        <ol>
                            <li><a href="#10.12.1">Main View</a></li>                            
                        </ol>
                    </li>
                </ol>
            </li>
            <li><a href="#11">Priorities</a>
                <ol>
                    <li><a href="#11.1">The Priority List</a></li>
                    <li><a href="#11.2">Adding Tasks</a></li>
                    <li><a href="#11.3">Removing Tasks</a></li>
                    <li><a href="#11.4">Clearing the List</a></li>
                    <li><a href="#11.5">Emailing Priorities</a></li>
                    <li><a href="#11.6">Supervisor Features</a>
                        <ol>
                            <li><a href="#11.6.1">Adding People to Lists</a></li>
                            <li><a href="#11.6.2">Removing People from Lists</a></li>
                            <li><a href="#11.6.3">Reorganizing Priority Lists</a></li>
                            <li><a href="#11.6.4">Switching Priority Lists</a></li>
                            <li><a href="#11.6.5">Creating Priority Lists</a></li>
                            <li><a href="#11.6.6">Deleting Priority Lists</a></li>
                        </ol>
                    </li>
                    <li><a href="#11.7">Sort Priority List by due date</a></li>
                    <li><a href="#11.8">Priority List Comment History</a></li>
                </ol>
            </li>
            <li><a href="#12">Time Zones</a>
                <ol>
                    <li><a href="#12.1">Your Time Zone</a></li>
                    <li><a href="#12.2">Time Zone Map</a></li>
                    <li><a href="#12.3">Scheduling Tasks</a></li>
                    <li><a href="#12.4">Bulk Time Zone Conversion</a></li>
                </ol>
            </li>
            <li><a href="#13">Mobile Version</a>
                <ol>
                    <li><a href="#13.1">General Comments</a></li>
                    <li><a href="#13.2">Show/Hide</a></li>
                    <li><a href="#13.3">Fonts</a></li>
                    <li><a href="#13.4">Searching Status Reports</a></li>
                    <li><a href="#13.5">Bulk Assignments</a></li>
                    <li><a href="#13.6">Comments from Emails</a></li>
                </ol>
            </li>
            <li><a href="#14">Miscellaneous Status Report Tips and Info</a>
                <ol>
                    <li><a href="#14.1">General Comments</a></li>
                    <li><a href="#14.2">Show/Hide</a></li>
                    <li><a href="#14.3">Fonts</a></li>
                    <li><a href="#14.4">Searching Status Reports</a></li>
                    <li><a href="#14.5">Bulk Assignments</a></li>
                    <li><a href="#14.6">Comments from Emails</a></li>
                </ol>
            </li>
            <li><a href="#15">Global Search</a></li>
            <li><a href="#16">Task History</a></li>
            <li><a href="#17">Notifications</a></li>
            <li><a href="#18">Automations</a>
                <ol>
                    <li><a href="#18.1">Linked Deadlines</a></li>
                    <li><a href="#18.2">Bulk Task Upload</a></li>
                </ol>
            </li>
            <li><a href="#99">Frequently Asked Questions</a></li>
        </ol>
    </div>
</div>


<!-- ============================================================
					GLOSSARY 
	 ============================================================ -->
<div class="glossary">
    <h1 class="glossary-header"><b>GLOSSARY OF TERMS</b></h1>

    <p><a id="g1"></a><b>1.Task</b></p>
    <p>A task is a job that you must complete by a specific due date. Every job, both on your status report and on your 'My Tasks' list is considered a task.</p>

    <p><a id="g2"></a><b>2. Checklist</b></p>
    <p>The checklist is the list of items which must be completed for a task to be considered done. The terms checklist and task can be used interchangeably in QProcess since every task has an associated checklist.</p>

    <p><a id="g3"></a><b>3. Checklist Item</b></p>
    <p>Checklist items are steps which must be completed to finish a task. Most checklist items are checkboxes (the rest being notes/headers).</p>

    <p><a id="g4"></a><b>4. Instance</b></p>
    <p>An instance is the intersection of a task and a schedule. For example, if you have a daily task, you would need to complete an instance on Monday, one on Tuesday, etc.</p>

    <p><a id="g5"></a><b>5. Upcoming Checklist / Upcoming Task</b></p>
    <p>An instance of a recurring task which is not active. For example, if I am working on my daily task on Monday, then Tuesday's instance is upcoming.</p>

    <p><a id="g6"></a><b>6. Active Checklist / Active Task</b></p>
    <p>An active task is the instance of a task which is currently being worked on. Only active tasks will appear on status reports. You can make upcoming tasks into active tasks by clicking 'reopen'.</p>

    <p><a id="g7"></a><b>7. Controller</b></p>
    <p>The controller is the user who can change an item. A task controller changes the setup of the task on the 'Manage Tasks' tab. A status report controller can alter the status report by adding new sections and tasks to the report.</p>

    <p><a id="g8"></a><b>8. Assignee</b></p>
    <p>An assignee is the user who is responsible for completing and checking off a task.</p>

    <p><a id="g9"></a><b>9. Alert</b></p>
    <p>An alert is an email message regarding a task. This may be an overdue message, or a reminder to complete the task by a certain time.</p>

    <p><a id="g10"></a><b>10. Reminder</b></p>
    <p>A reminder is a specific type of alert which is sent only to those who are assigned to a task.</p>

    <p><a id="g11"></a><b>11. Template</b></p>
    <p>A template is a task which you may copy in the future in order to create new, similar tasks.</p>

    <p><a id="g12"></a><b>12. Group</b></p>
    <p>A group is a set of users who can be assigned as a whole to a task or status report.</p>

    <p><a id="g13"></a><b>13. Supervisor</b></p>
    <p>A supervisor is the user who is responsible for commenting on your status report. This is most likely the person who you report to.</p>

    <p><a id="g14"></a><b>14. Interested Party</b></p>
    <p>An interested party is any user who needs to view your status report, but does not necessarily need to add any comments.</p>

    <p><a id="g15"></a><b>15. Priority List</b></p>
    <p>A priority list is a collection of tasks that you are working on now, or will be working on in the near future. Its purpose is to help supervisors manage the to-do lists of their teams. This is different from a group status report that may contain tasks that relate to a single project, or personal status reports which may contain tasks that don't need to be started until weeks or months in the future.</p>

    <p><a id="g16"></a><b>16. Supervisor Controlled Task</b></p>
    <p>When creating a new task, you will be given the choice of whether you control the task or if the task needs to be supervisor controlled.&nbsp; A &quot;supervisor controlled task&quot; is one where a supervisor needs to know about and approve any changes that you make to a task.&nbsp; That may be your supervisor, a partner, or Geoffrey.&nbsp; If you are unsure whether a task should be supervisor controlled or who should control it, ask.</p>

    <p><a id="g17"></a><b>17. Soft Deadline</b></p>
    <p>Because assignees may no longer be able to "roll" tasks forward on their own, there is a need to see some tasks on your calendar or at the top of a status report well before the actual deadline.&nbsp; To make this possible, all tasks now have a soft deadline.&nbsp; The soft deadline lets you see a task on your calendar before the task is actually due so you can start work on it.&nbsp; Assignees can move soft deadlines at any time without controller approval.</p>

    <p><a id="g18"></a><b>18. Change Request</b></p>
    <p>When an assignee wants to make a change to a task, a change request will be sent to the task controller(s).&nbsp; Controllers then approve, modify, or reject change requests.&nbsp; A single change request can contain one or more changes to a task.&nbsp; For example, one change request might be created only to move a deadline back a week.&nbsp; Another change request might have a deadline change, a change to assignees on a task, and changes to what checkboxes show up on a checklist.&nbsp; All three changes (due date, assignees, and checklist items) are accepted or rejected as a group.</p>
</div>
<div>
    <!-- ============================================================
					1. MY TASKS
	 ============================================================ -->
    <h1 class="title"><b>HOW TO USE <%= QProcess.Configuration.AppSettings.AppName.ToUpperInvariant()%></b></h1>

    <h2><a id="1"></a>1. My Tasks</h2>
    <p>The 'My Tasks' tab is the page that you will use to check off and complete tasks. Here you will find a list of all the tasks which you are responsible for completing. You can check off and save individual steps, add comments, mark tasks as 'N/A', or export your entire task list using this page.</p>

    <h3><a id="1.1"></a>1.1 Task Type Filter</h3>
    <p>The task type filter allows you to filter the view on the 'My Tasks' tab. The four options you may select are 'All', 'One Time', 'Recurring', and 'Open' tasks. 'Open' removes future occurrences of recurring tasks. After selecting which set of tasks you want, click the 'Filter' button.</p>
    <img id="Picture 1" src="/Images/Help/image001.png">
    <br />

    <h3><a id="1.2"></a>1.2 Date Range Filter</h3>
    <p>The date range filter allows you to limit the tasks shown on the 'My Tasks' tab by due date. Only those tasks with due dates inside the range you select will be shown. After selecting the appropriate range, click the 'Filter' button.</p>
    <img id="Picture 2" src="/Images/Help/image002.png">
    <p>If you change this filter, the number of days you have selected will be remembered for the next time you use this tab. The default is one week prior to, and one week after the current date.</p>

    <h3><a id="1.3"></a>1.3 The Checklist Header</h3>
    <p>
        From the checklist header, you can tell the status of a task and when it is due.<br>
        Tasks that you are working on now will be bold and black.
    </p>
    <img id="Picture 5" src="/Images/Help/image003.jpg" />
    <p>Overdue tasks are marked as overdue in red.</p>
    <img id="Picture 4" src="/Images/Help/image004.gif" />
    <p>Once a task is completed, it will move to the bottom of your list and the heading will be greyed out.</p>
    <img id="Picture 3" src="/Images/Help/image005.jpg" />
    <br />

    <h3><a id="1.4"></a>1.4 Expanding</h3>
    <p>By default, the all tasks on the 'My Tasks' tab will be collapsed on the page. You can toggle each individual task by clicking the toggle button attached.</p>
    <img id="Picture 9" src="/Images/Help/image006.png">
    <p>After expanding a task, you can see the current controllers on that task, as well as a View Alerts link. Clicking the link displays all alerts that are currently set up for that task.</p>
    <img id="Picture 7" src="/Images/Help/image007.jpg" />
    <p>In addition, you can toggle <i>all</i> tasks by using the toggle buttons at the top of the page.</p>
    <img id="Picture 10" src="/Images/Help/image008.png">
    <br />

    <h3><a id="1.5"></a>1.5 Exporting</h3>
    <p>
        You can export the contents of the 'My Tasks' tab into excel for read-only use by clicking the export
        <img id="Picture 11" src="/Images/Help/image009.gif" />
        button at the top of the page. The exported list prints cleaner than the browser, so use this function if you are familiar with printing in excel.
    </p>

    <h3><a id="1.6"></a>1.6 Completing a Step</h3>
    <p>
        To complete a step on a checklist, check the checkbox
        <img id="Picture 16" src="/Images/Help/image010.png" />
        and click the save
        <img id="Picture 12" src="/Images/Help/image011.gif" />
        button.
    </p>

    <h3><a id="1.7"></a>1.7 N/A a checklist</h3>
    <p>
        In some circumstances, a checklist may no longer be applicable. For this special case, a N/A button
        <img id="Picture 18" src="/Images/Help/image012.gif" />
        has been provided as a shortcut. After pressing this button, all steps on the checklist are checked off and 'N/A' is added to the comments.
    </p>
    <img id="Picture 19" src="/Images/Help/image013.png" />
    <p>Please note, you will still need to complete the checklist. N/A only completes the steps, not the checklist itself.</p>

    <h3><a id="1.8"></a>1.8 Exporting a checklist</h3>
    <p>
        An individual checklist may be exported using the export button at the bottom of each checklist. Click
        <img id="Picture 22" src="/Images/Help/image014.png" />
        to export the checklist to excel.
    </p>

    <h3><a id="1.9"></a>1.9 Completing a Checklist</h3>
    <p>
        When you have finished all the steps of a checklist, you will need to complete it in order to mark it as done. To complete the checklist, click the
        <img id="Picture 21" src="/Images/Help/image015.gif" />
        button at the bottom of the checklist. Until the checklist is complete, any overdue alerts that are associated with the task may be sent.
    </p>
    <p>You may click the Complete button on a checklist with one step, without checking the step first. If the checklist has two or more steps, you must first check off each of the individual steps before clicking Complete.</p>
    <br />

    <h3><a id="1.10"></a>1.10 Get Task Extension</h3>
    <p>
        When selecting the ‘get task extension' button you will enter a reason,
        and one change request will be created (if approved) and adds a 
        2 hour extension to the deadline of any task assigned to you that is due 
        within 2 hours (and not already overdue).
    </p>
    <img id="Picture 166" src="/Images/Help/image166.png" />
    <br />
    <h3><a id="1.11"></a>My Tasks Search</h3>
    <p>
        By clicking the "search page" button at the top right of Qprocess, the search bar will appear. 
        Click on the search bar, and your 10 most recent searches will be suggested. 
        You can also click on one of the suggested words and it will populate and search for you.
    </p>
    <img id="Picture 250" src="/Images/Help/image250.png" />
    <p>
        As you begin typing, results will be returned based on what you have typed so far. 
        This will return both task names, and items matching within the checklist.
    </p>
    <img id="Picture 251" src="/Images/Help/image251.png" />

    <p><b>When selecting "Advanced Matching" Boolean Operators can be used.</b></p>
    <p>Selecting "must match all words" - when searching more than one word, this option will return only tasks that contain all of the words entered in the search textbox.</p>
    <p>Selecting "can match any word" - when searching more than one word, this option will return tasks that contain <i>any</i> of the words entered in the textbox. For example, searching <b>"Q Family Office"</b> will return tasks with <b>Q, Family,</b> or <b>Office</b></p>
    <p>Selecting "advanced matching" - enables the use of Boolean operators (such as <b>AND, OR, </b>and <b>NOT</b>) to create more precise search queries.</p>
    <p>The search string <b>Final AND (Test OR QProcess)</b></p>
    <ul>
        <li><b>AND:</b> The AND operator requires the terms on either side of it to both exist, but it searches for them independently.</li>
        <li><b>OR:</b> The OR operator requires at least one of the two search terms on either side to match.</li>
        <li><b>NOT:</b> The NOT operator excludes any task matching the search term after it.</li>
    </ul>
    <p>Note order of operations matters, the use of parenthesis is important when using multiple Boolean operators, for example: match all tasks that included the word "Final" and either the word "Test" or the word "QProcess", you can use parentheses to guide the search behavior.</p>
    <ul>
        <li>Some more helpful hints using Boolean operators
            <ul>
                <li>These search terms are <i>not</i> case sensitive</li>
                <li>Multi-word terms <i>must</i> be double quotes, regardless of anything else in the search. "Q Family Office"</li>
                <li>Semicolons - <b>;</b> - cannot appear anywhere in the search criteria</li>
                <li>You <i>can</i> search "and", "or", and "not", and for tasks containing parentheses; simply make sure they're in double-quotes. <b>"Complete and Final Test (not intermediate)"</b> will match any task with exactly that sequence of characters somewhere in its title, checklist or comments.</li>
            </ul>
        </li>
    </ul>
    <p style="color:red">Please note: Search is refreshed hourly, so new tasks may not appear in search results for up to an hour after task creation.</p>

    <h3><a id="1.12"></a>Task History</h3>
    <p>To view the history of any changes made to a task click on the task and click the "task history" button. Here you will see all comment, deadline, and change request history.</p>
    <img id="TskHis-1" src="/Images/Help/TskHis-1.png" />


    <!-- ============================================================
					2. THE CALENDAR
	 ============================================================ -->
    <h2><a id="2"></a>2. The Calendar</h2>
    <p>The Checklist Calendar organizes all the checklists that you have access to by due date.</p>

    <h3><a id="2.1"></a>2.1 Selecting a Day</h3>
    <p>To see the tasks due on a specific day, find the day on the calendar on the left. To go to a different month, select the appropriate month/year using the arrows at the top. To return to today, click the 'Today' button.</p>
    <img id="Picture 24" src="/Images/Help/image016.png" />
    <p>Once you have clicked on the appropriate day, the associated work week will show up on the detail calendar on the right. The selected day will be highlighted in blue.</p>

    <h3><a id="2.2"></a>2.2 Using the Key</h3>
    <p>The key on the left describes the symbols and colors used on the calendar.</p>
    <img id="Picture 27" src="/Images/Help/image017.png" />
    <p>&quot;My tasks&quot; are tasks that you are responsible for completing.</p>
    <p>&quot;Tasks I Control&quot; are tasks that you can modify on the &quot;Manage Tasks&quot; tab without sending a change request.</p>
    <p>&quot;Active Task&quot; are tasks that can be completed now.</p>
    <p>&quot;Soft Deadlines&quot; act as a one-time reminder of an upcoming due date</p>
    <p>&quot;Recurring Soft Deadlines&quot; show the reminder daily until the due date</p>
    <p>&quot;Overdue Task&quot; are tasks which have passed their deadline.</p>
    <p>&quot;Completed Task&quot; are tasks that have been marked complete.</p>
    <p>&quot;Future Task - Not Yet Active&quot; are the recurring tasks which are not yet open.</p>
    <p>Most tasks will include a combination of the above. For example, the task below is one in which you are responsible for, you control, and it is complete:</p>
    <img id="Picture 29" src="/Images/Help/image018.png" />
    <br />

    <h3><a id="2.3"></a>2.3 Filtering</h3>
    <p>You can use the dropdown on the bottom left of the page to filter which items you want to show on the page. The default is those tasks &quot;Assigned To Me&quot;, but you can also see tasks assigned to specific users, and tasks on a specific status report. To see these tasks, simply select the appropriate filter from the dropdown. To see all the tasks that you have access to see, select 'All'. </p>
    <img id="Picture 31" src="/Images/Help/image019.png" />
    <br />

    <h3><a id="2.4"></a>2.4 Viewing a Checklist</h3>
    <p>To view the checklist associated with a task on your calendar, click on the task.</p>
    <img id="Picture 33" src="/Images/Help/image020.png" />
    <p>If you have access to complete this checklist, you can use it in the same way as described in the &quot;My Tasks&quot; section of this help.</p>
    <br />
    <h3><a id="2.5"></a>2.5 Get Task Extension</h3>
    <p>
        When selecting the ‘get task extension' button you will enter a reason, 
        and one change request will be created (if approved) and adds a 
        2 hour extension to the deadline of any task assigned to you that is due within 
        2 hours (and not already overdue).
    </p>
    <img id="Picture 165" src="/Images/Help/image165.png" />

    <h3><a id="2.6"></a>2.6 Calendar Search</h3>
    <p>By clicking the "search page" button at the top right of Qprocess, the search bar will appear. Click on the search bar, and your 10 most recent searches will be suggested. You can also click on one of the suggested words and it will populate and search for you.</p>
    <img id="Picture 259" src="/Images/Help/image259.png" />
    <p>As you begin typing, results will be returned based on what you have typed so far. This will return both task names, and items matching within the checklist.</p>
    <img id="Picture 251 Calendar" src="/Images/Help/image251.png" />
    <p><b>When selecting "Advanced Matching" Boolean Operators can be used.</b></p>
    <p>Selecting "must match all words" - when searching more than one word, this option will return only tasks that contain all of the words entered in the search textbox.</p>
    <p>Selecting "can match any word" - when searching more than one word, this option will return tasks that contain <i>any</i> of the words entered in the textbox. For example, searching <b>"Q Family Office"</b> will return tasks with <b>Q, Family,</b> or <b>Office</b></p>
    <p>Selecting "advanced matching" - enables the use of Boolean operators (such as <b>AND, OR, </b>and <b>NOT</b>) to create more precise search queries.</p>
    <p>The search string <b>Final AND (Test OR QProcess)</b></p>
    <ul>
        <li><b>AND:</b> The AND operator requires the terms on either side of it to both exist, but it searches for them independently.</li>
        <li><b>OR:</b> The OR operator requires at least one of the two search terms on either side to match.</li>
        <li><b>NOT:</b> The NOT operator excludes any task matching the search term after it.</li>
    </ul>
    <p>Note order of operations matters, the use of parenthesis is important when using multiple Boolean operators, for example: match all tasks that included the word "Final" and either the word "Test" or the word "QProcess", you can use parentheses to guide the search behavior.</p>
    <ul>
        <li>Some more helpful hints using Boolean operators
            <ul>
                <li>These search terms are <i>not</i> case sensitive</li>
                <li>Multi-word terms <i>must</i> be double quotes, regardless of anything else in the search. "Q Family Office"</li>
                <li>Semicolons - <b>;</b> - cannot appear anywhere in the search criteria</li>
                <li>You <i>can</i> search "and", "or", and "not", and for tasks containing parentheses; simply make sure they're in double-quotes. <b>"Complete and Final Test (not intermediate)"</b> will match any task with exactly that sequence of characters somewhere in its title, checklist or comments.</li>
            </ul>
        </li>
    </ul>
    <p style="color:red">Please note: Search is refreshed hourly, so new tasks may not appear in search results for up to an hour after task creation.</p>
    
    <h3><a id="2.7"></a>2.7 Calendar Email Summary</h3>
    <ul>
        <li>Your task list for the calendar week can be automatically emailed to you on Monday mornings if toggled on in your preferences section.</li>
    </ul>
    <img id="Picture 260" src="/Images/Help/image260.png" />
    <br />
    <img id="Picture 261" src="/Images/Help/image261.png" />
    <br />
    <br />
    <!-- ============================================================
					3. MANAGE TASKS
	 ============================================================ -->
    <h2><a id="3"></a>3. Manage Tasks</h2>
    <p>The Manage Tasks tab is used to alter the configuration of a task that you control or to request changes to tasks assigned to you.</p>

    <h3><a id="3.1"></a>3.1 Filters</h3>
    <p>Three filters are provided for the Manage Tasks page, an assigned to filter, a controlled by filter, and a search filter.</p>
    <img id="Picture 34" src="/Images/Help/image021.gif">
    <p>These filters allow you to filter down and find the specific task you are looking for. By default, all assignees and controllers are selected, but you can change the dropdown to filter to a specific assignee, controller, or both. The search filter allows you to search for text in the name of the task (or any items in the task) you are looking for. Type in the appropriate text and press &lt;enter&gt; to search. Once you apply your filter, only those tasks that apply will be shown in the folder tree.</p>

    <h3><a id="3.2"></a>3.2 Folder Structure</h3>
    <p>The tasks on the Manage Tasks page can be organized into a folder structure to help you keep track of all your tasks.</p>

    <h3><a id="3.2.1"></a>3.2.1 Default Setup</h3>
    <p>By default, all checklists you control or are assigned are shown in an alphabetized list on the left side of the Manage Tasks page.</p>
    <img id="Picture 39" src="/Images/Help/image022.gif" />
    <br />

    <h3><a id="3.2.2"></a>3.2.2 Adding Folders and Sub-Folders</h3>
    <p>To begin organizing tasks, click the ‘+ Add Folder' link at the top of the list to create a new root-level folder.</p>
    <img id="Picture 39a" src="/Images/Help/image022a.gif" />

    <p>The folder will be created with the name ‘New Folder'. This name can easily be changed; see <a href="#3.2.3">Renaming Folders</a> for instructions.</p>
    <img id="Picture 39b" src="/Images/Help/image022b.gif" />

    <p>You may also create sub-folders of any existing folders. Simply right-click the folder and choose ‘Add Sub-Folder', and the new sub-folder will be created.</p>
    <img id="Picture 38" src="/Images/Help/image023.gif" />
    <br />

    <h3><a id="3.2.3"></a>3.2.3 Renaming Folders</h3>
    <p>At any time, you can change the name of any folder by right clicking on the folder and selecting ‘Rename'.</p>
    <img id="Picture 40" src="/Images/Help/image025.gif" />
    <p>The folder name will become editable. Simply type the new name and press ‘Enter' to save. You may press ‘Esc' to cancel renaming.</p>
    <img id="Picture 37" src="/Images/Help/image024.gif" />
    <br />

    <h3><a id="3.2.4"></a>3.2.4 Deleting Folders</h3>
    <p>To delete a folder, right click on the folder and choose delete. You will be prompted to confirm this action. All folders and tasks in that folder will move to the parent folder.</p>
    <img id="Picture 41" src="/Images/Help/image026.gif" />
    <br />

    <h3><a id="3.2.5"></a>3.2.5 Moving Tasks/Folders</h3>
    <p>To place checklists in a folder, simply click and drag them from the list to the folder. Additionally, you can drag folders into other folders to create nested sub-folders.</p>
    <img id="Picture 42" src="/Images/Help/image027.gif" />
    <br />

    <h3><a id="3.3"></a>3.3 Deleting</h3>
    <p>
        You have the ability to delete the tasks that you control. Click the task from the task list on the left and click the
        <img id="Picture 44" src="/Images/Help/image028.gif" />
        button to delete. Deleting tasks does not actually remove them from the system. Instead, they are moved to an archive which cannot be accessed from the user interface.
    </p>
    <img id="Picture 46" src="/Images/Help/image029.jpg" />
    <p>You may also delete tasks by right clicking the appropriate task, and selecting 'Delete' from the context menu.</p>

    <h3><a id="3.4"></a>3.4 Expanding</h3>
    <p>By default, all the sections of the task control are minimized. However, you can expand this out (and minimize back) using the task toggle buttons.</p>
    <img id="Picture 48" src="/Images/Help/image030.jpg">
    <br />

    <h3><a id="3.5"></a>3.5 Copying</h3>
    <p>
        Any task can be used as a template to create new tasks. To copy a task, click the
        <img id="Picture 52" src="/Images/Help/image031.gif" />
        button. All attributes of the task are copied into a new task with a prefix of 'Copy of '.
    </p>
    <img id="Picture 53" src="/Images/Help/image032.png">
    <br />

    <h3><a id="3.6"></a>3.6 Naming</h3>
    <p>
        Change the name of a checklist by changing the text in the 'Naming' text box and clicking the
        <img id="Picture 50" src="/Images/Help/image033.gif" />
        button.
    </p>
    <img id="Picture 49" src="/Images/Help/image034.gif" />
    <p>You can also rename a task by right clicking the task in the tree structure on the left pane, and selecting 'Rename'.</p>

    <h3><a id="3.7"></a>3.7 Controllers</h3>
    <p>Controllers are the users who can alter a task on the 'Manage Tasks' page. To give someone else the ability to control this task, select their name from the controllers dropdown and click the 'Add' button.</p>
    <img id="Picture 76" src="/Images/Help/image035.png" />
    <p>
        To remove a user's access to control the task, click the
        <img id="Picture 74" src="/Images/Help/image028.gif" />
        button by the user's name.
    </p>
    <img id="Picture 6" src="/Images/Help/image036.png" />
    <br />

    <h3><a id="3.8"></a>3.8 Items</h3>
    <p>To add an item to a task, select the item type, fill in the text and URL (optional), and click the Add button.</p>
    <img id="Picture 8" src="/Images/Help/image037.jpg" />
    <p>
        To remove an item, click the
        <img id="Picture 17" src="/Images/Help/image038.png">
        button by the item.
    </p>
    <img id="Picture 13" src="/Images/Help/image039.jpg" />
    <p>
        You can also edit each item using the
        <img id="Picture 14" src="/Images/Help/image040.png" />
        button, or swap the order of items using the
        <img id="Picture 20" src="/Images/Help/image041.png" />
        button
    </p>
    <p>
        When you are done editing, click
        <img id="Picture 67" src="/Images/Help/image033.gif" />.
    </p>
    <p>Preview what the task will look like to the user using the 'Preview' button.</p>

    <h3><a id="3.9"></a>3.9 Assignments</h3>
    <p>An assignment encompasses the assignees, the schedule, and the alerts of a task.</p>
    <p>A task can have multiple assignments if it runs on multiple schedules.</p>

    <h3><a id="3.9.1"></a>3.9.1 Expanding</h3>
    <p>
        To expand an assignment, click the
        <img id="Picture 23" src="/Images/Help/image042.png" />
        button by the assignment.
    </p>

    <h3><a id="3.9.2"></a>3.9.2 Copying</h3>
    <p>You can use an assignment as a template to create new assignments. For example, if you have a task that runs on the 7th and the 13th of each month, the best way to create this is with two assignments. First create one monthly assignment that starts on the 7th. Copy this assignment and change the start date to the 13th and you are done.</p>
    <p>
        To copy an assignment, click the
        <img id="Picture 65" src="/Images/Help/image031.gif" />
        button by the assignment.
    </p>
    <img id="Picture 64" src="/Images/Help/image043.gif" />
    <br />

    <h3><a id="3.9.3"></a>3.9.3 Assigned To</h3>
    <p>
        Every task needs to be assigned to someone responsible for completing the task. To assign a new user, select the user from the assign dropdown and click 'Add'. To remove an assignee, use the
        <img id="Picture 25" src="/Images/Help/image041.png" />
        button.
    </p>
    <img id="Picture 28" src="/Images/Help/image044.png">
    <br />

    <h3><a id="3.9.4"></a>3.9.4 Status Reports</h3>
    <p>
        Any assignment may be added to your status report so you can monitor its progress. To add to a status report, select the Status Report name and Section from the dropdowns and click 'Go'. To remove a status report, use the
        <img id="Picture 32" src="/Images/Help/image041.png">
        button.
    </p>
    <img id="Picture 30" src="/Images/Help/image045.png" />
    <br />

    <h3><a id="3.9.5"></a>3.9.5 Scheduling</h3>
    <p>Each assignment must have a schedule to determine when the task starts and when it is due. Answer the on-screen questions about how often the task should start.</p>
    <img id="Picture 35" src="/Images/Help/image046.png" />
    <p>*Please note, the weekend and holiday question applies ONLY to when the task will start. These tasks may still be due on a weekend or holiday if they are allowed to be completed 1 or more days later.</p>

    <h3><a id="3.9.6"></a>3.9.6 Alerts</h3>
    <p>
        Alerts are similar to Reminders, but they can go to any user (not just those who are assigned). To add an alert, select what type of alert is appropriate and the user that should be alerted. Click 'Add' to remove an alert, use the
        <img id="Picture 36" src="/Images/Help/image041.png">
        button.
    </p>
    <img id="Picture 57" src="/Images/Help/image047.gif" />
    <br />

    <h3><a id="3.9.7"></a>3.9.7 Working on Now</h3>
    <p>At the top of the assignments section, each task which is currently being worked on has a 'Working on now' area. Here you will find the individual tasks with their due dates. To alter a due date, or delete the individual instance, click on the link provided.</p>
    <img id="Picture 56" src="/Images/Help/image048.gif" />
    <p>Please check the working on now after any schedule change to ensure that the current schedule looks correct.</p>

    <h3><a id="3.10"></a>3.10 Templates</h3>
    <p>Each task in the QProcess system that is no longer useful should be deleted. In order to help you keep up with this, tasks will automatically be deleted after their last due date.</p>
    <p>However, you will want to keep some tasks as templates for future use. To mark a task as a template and keep it from being deleted by the system, right-click on the task and select 'Toggle Template'. All tasks in bold are template tasks; these tasks will not be archived. To remove the template designation from a task, perform the same steps again.</p>
    <img id="Picture 43" src="/Images/Help/image049.png" />
    <br />

    <h3><a id="3.11"></a>3.11 Change Requests</h3>
    <p>When you open a task on the Manage Tasks tab that you do not control, you will see Request Change and Cancel Change buttons. After you have made changes, you MUST click the Request Change button for your change request to be saved and sent to the task controller.</p>
    <img id="Picture 54" src="/Images/Help/image050.gif" />
    <p>When you click Request Change, an e-mail will be sent to the task controller(s) letting them know you have a new change request requiring their attention. When the task controller approves or denies your change, you will receive an e-mail letting you know of their decision.</p>
    <p>If instead you don't want to make any changes, click Cancel Change and your change request will go away.</p>
    <br />

    <h3><a id="3.12"></a>3.12 Export to Excel</h3>
    <p>Click this button to export ALL active tasks on the Manage Tasks tab to a .xlsx file sorted by due date. </p>
    <img id="EXP-1" src="/Images/Help/exp-1.png" />
    
    <br />
    <br />
    <!-- ============================================================
					4. NEW TASKS
	 ============================================================ -->
    <h2><a id="4"></a>4. New Tasks</h2>
    <p>Use the New Tasks tab to create new tasks.</p>

    <h3><a id="4.1"></a>4.1 Default or Customized?</h3>
    <p>Default tasks are a shortcut to creating a task. A default task will be setup as a one time checklist with one step and a reminder. These are the same as the the tasks which are created through the status report part of the application. If you want a more complex setup for your task, use the Customized Task option.</p>
    <img id="Picture 45" src="/Images/Help/image051.png" />
    <br />

    <h3><a id="4.2"></a>4.2 Default Task Creation</h3>
    <p>For a default task, fill in the task name, choose an assignee, choose a due date and soft due, and decide who should be the controller. For most tasks, you'll probably want a supervisor to be the controller.</p>
    <img id="Picture 47" src="/Images/Help/image052.gif" />
    <br />

    <h3><a id="4.3"></a>4.3 Customized Task Creation</h3>
    <p>To create a customized task, you will have to go through all the detailed steps individually. For help on individual steps of customized task creation, view the 'Manage Tasks' help above.</p>

    <h3><a id="4.4"></a>4.4 Creating Tasks from Email</h3>
    <p>It's possible to create tasks from an e-mail. For basic tasks, just send an e-mail to <a href="mailto:<%=TaskEmail%>"><%=TaskEmail%></a> with the task name in the subject line. The task will be created with all defaults.</p>
    <p>If you want to change something about the task to something other than the default, such as the due date or who is assigned to the task, that can be done as well. Send a blank e-mail to <a href="mailto:<%=TaskEmail%>"><%=TaskEmail%></a> for full instructions.</p>
    <p>
        Your defaults for tasks created from e-mails can be different from the defaults when you create a task on the New Tasks tab. To change your defaults for tasks created from e-mails, click the
        <img id="Picture 99" src="/Images/Help/image053.gif" />
        link at the bottom of QProcess. From there you can change your defaults.
    </p>
    <img id="Picture 79" src="/Images/Help/image054.png" />

    <h3><a id="4.5"></a>4.5 Create a task from template</h3>
    <p>These are the templates previously made by the user from the <i>Manage Tasks</i> Tab.  New tasks can be created following a template of a previous task. After choosing a template be sure to assign a name to this task.</p>
    <img id="NT-1" src="/Images/Help/NT-1.png" />
    <br />
    <br />
    <!-- ============================================================
					5. CHANGE REQUESTS
	 ============================================================ -->
    <h2><a id="5"></a>5. Change Requests</h2>
    <p>The Change Requests tab shows all change requests related to you, both the ones waiting for your approval and the ones you have sent to others to approve. Font size and row heights can be adjusted using the sliders. Column width can be adjusted by dragging column sides left or right.</p>
    <img id="Picture 86" src="/Images/Help/image055.png" />
    <br />

    <h3><a id="5.1"></a>5.1 Changes to Tasks I Control</h3>
    <p>Under the section &quot;Other People's Requests for Changes to Tasks I Control&quot;, if you have change requests waiting on your approval you will get a grey box for each change request, with Approve, Deny and Change/View buttons.</p>
    <img id="Picture 87" src="/Images/Help/image056.png" />
    <p>
        Click the
        <img id="Picture 88" src="/Images/Help/image042.png" />
        next to a change to see what change the assignee is requesting
    </p>
    <img id="Picture 89" src="/Images/Help/image057.jpg" />
    <p>You can see what was changed, added, and removed from the task as part of this change request. In this example, you can see in the Changed section that the task due date was changed from "Sep 30 2013 6:00PM" to an October date. The Current column shows the current state of the task, and the Requested column shows what was requested.</p>
    <p>You can also see that the assignee has requested a new checkbox be added, and a checkbox be removed.</p>
    <p>The Approve and Deny buttons work as expected and will notify the employee of your decision. The Change / View button takes you to the Manage Tasks tab. You will see the task <b>with the change applied</b>. This is a convenient way to see what the task will look like if you approve the change. You can also modify the change any way you would like.</p>
    <p>Notice in the screenshot that the new checklist name is shown, as well as the new checklist item:</p>
    <img id="Picture 82" src="/Images/Help/image058.gif" />
    <p>Also notice that there are Approve and Deny buttons at the bottom of the screen. If you make changes to the task on top of what the employee requested, you must click Approve for the change to be saved.</p>

    <h3><a id="5.2"></a>5.2 My Requests to Others</h3>
    <p>This section works the same as Changes to Tasks I Control, except that you are unable to approve or deny changes. Its purpose is to let you see requests you have made and modify them if necessary.</p>

    <h3><a id="5.3"></a>5.3 Change Request Emails</h3>
    <p>When a change request is sent, both the requester and the task controller(s) will receive an e-mail describing what change has been requested. If you are a controller on the task, you can simply reply to that e-mail and put a Y or N as the first line of your reply to approve or deny the requested change. If you wish to make further comments so the requester understands your decision, do a reply all instead of reply and simply type anything you want on the next line down below the Y or N.</p>

    <!-- ============================================================
					6. REPORTS
	 ============================================================ -->
    <h2><a id="6"></a>6. Reports</h2>
    <p>The Reports page can be used to view summary information on the tasks that you have access to. First select the type of report you would like to see</p>

    <h3><a id="6.1"></a>6.1 Overdue</h3>
    <p>To view the Overdue report, click 'Overdue' in the menu on the left.</p>
    <p>The Overdue report shows a list of all tasks which are past due.</p>
    <p>You can sort the list using the sorting dropdown at the top.</p>
    <img id="Picture 92" src="/Images/Help/image059.gif" />
    <br />

    <h3><a id="6.2"></a>6.2 History</h3>
    <p>To view the History report, click 'History' in the menu on the left.</p>
    <p>The History report shows a report on tasks which have been completed in the past.</p>
    <p>You can filter down the results using the filters at the top of the page. </p>
    <img id="Picture 91" src="/Images/Help/image060.gif" />
    <p>Click 'Run Report' to run the report.</p>
    <!-- ============================================================
					7. GROUPS
	 ============================================================ -->
    <h2><a id="7"></a>7. Groups</h2>
    <p>The groups tab allows you to place QProcess users into groups so that task, and status reports can be assigned to the group as a whole. This will be especially useful when moving new users in and out of a department.</p>

    <h3><a id="7.1"></a>7.1 Adding Groups</h3>
    <p>To add a group, go to the Groups tab, type in the group name and click the plus sign beside 'Add Group'.</p>
    <p>Once you have added your group, it will show up in the list of groups and you can begin adding members. The list of groups will show you which groups you are in, and which group you own. The creator (owner) of a group is the only person who can edit it.</p>
    <img id="Picture 97" src="/Images/Help/image061.jpg" />
    <br />

    <h3><a id="7.2"></a>7.2 Editing/Viewing Groups</h3>
    <p>Any group that you have created will have an 'Edit' link, and all others will have a 'View' link. To edit the group members, click the 'Edit' link. Here you can add or remove members from the group.</p>
    <img id="Picture 98" src="/Images/Help/image062.png" />
    <p>
        You can view all members of all groups in QProcess by clicking the
        <img id="Picture 94" src="/Images/Help/image063.gif" />
        link at the bottom of the page.
    </p>
    <img id="Picture 101" src="/Images/Help/image064.png">
    <br />

    <h3><a id="7.3"></a>7.3 Removing Groups</h3>
    <p>To remove a group, click the red x beside the group name. Please be careful not to delete groups unless you are sure they are no longer responsible for tasks.</p>
    <!-- ============================================================
					8. TASK SUMMARY
	 ============================================================ -->
    <h2><a id="8"></a>8. Task Summary</h2>
    <p>The Task Summary Page gives you an overview of vital information on all of the active tasks which you have access to.</p>
    <p>It also helps you manage the placement of tasks onto status reports.</p>

    <h3><a id="8.1"></a>8.1 Assigned To Me - No Status</h3>
    <p>The Assigned To Me - No Status grid shows a list of all the active tasks which I am responsible for that are not placed on a status report.</p>
    <img id="Picture 111" src="/Images/Help/image065.gif" />
    <br />

    <h3><a id="8.2"></a>8.2 Assigned To Me - With Status</h3>
    <p>The Assigned To Me - With Status grid shows a list of all the active tasks which I am responsible for that <b><i>are</i></b> placed on a status report.</p>
    <p>The list will look very similar to your status report, with only the comments missing.</p>
    <img id="Picture 110" src="/Images/Help/image066.gif" />
    <br />

    <h3><a id="8.3"></a>8.3 Assigned To Others</h3>
    <p>The Assigned To Others grid shows a list of all the active tasks which I am manage which are assigned to other people.</p>
    <img id="Picture 109" src="/Images/Help/image067.gif" />
    <br />

    <h3><a id="8.4"></a>8.4 Viewing Checklists</h3>
    <p>The task summary page will also allow you to view the checklists that are associated to your active tasks.</p>
    <p>To view any active checklist on this page, click on the task name.</p>
    <img id="Picture 108" src="/Images/Help/image068.gif" />
    <p>To view the last completed checklist associated with this task, click the last completed date.</p>
    <img id="Picture 107" src="/Images/Help/image069.gif" alt="images/qcheckhelp_lc.gif">
    <p>To view the next upcoming checklist associated with this task, click the next start time.</p>
    <img id="Picture 106" src="/Images/Help/image070.gif" />
    <br />

    <h3><a id="8.5"></a>8.5 Moving Tasks to Status Reports</h3>
    <p>
        In addition to information on tasks, this page is used to organize your active tasks into their appropriate status reports. If you only have a few tasks shown on the page it is easiest to just drag any task to the section on a status report that it should go on. Click and drag the
        <img id="Picture 105" src="/Images/Help/image071.gif" />
        button and drag it to where it should go.
    </p>
    <img id="Picture 104" src="/Images/Help/image072.gif" />
    <p>To remove a task from a status report, drag it to 'No Status' grid.</p>
    <p>
        If dragging is not an option, click on the
        <img id="Picture 103" src="/Images/Help/image071.gif" />
        button (without dragging).
    </p>
    <p>A popup will appear which will allow you to add or remove status reports for this task.</p>
    <img id="Picture 102" src="/Images/Help/image073.gif" />
    <br />
    <!-- ============================================================
					9. MY STATUS
	 ============================================================ -->
    <h2><a id="9"></a>9. My Status</h2>
    <p>My Status is the place where you will view and update the status reports you control.</p>

    <h3><a id="9.1"></a>9.1 Supervisors/Interested Parties</h3>
    <p>To view the current list of supervisors and interested parties for the selected status report, click the 'Supervisors' button under the 'Report' menu. If you wish to modify the list of supervisors/interested parties, you must send a written request via email to <a href="mailto:<%=GradingEmail %>"><%=GradingEmail %></a>.</p>
    <p>Supervisors are people who need to be commenting on the status reports regularly. Interested Parties are those that need to see the conversation infrequently.</p>
    <p>NOTE: Do not request to have a user added to a status report as a supervisor or interested party who is already listed as a controller. A user can only be a controller or a supervisor/interested party on a report, not both. If the user should be a supervisor/interested party on the report, remove that user as a controller (see <a href="#9.13">9.13: Controllers</a>).</p>

    <h3><a id="9.2"></a>9.2 Sections</h3>
    <p>Next you will need to setup your sections.&nbsp; These sections provide the subheadings which separate your status report out into different categories.&nbsp; Below is an example of a task that has been saved to the custom �Programming Tasks' section: </p>
    <img id="Picture 15" src="/Images/Help/image074.png" />
    <p>The default setup gives you 'General Comments', 'Current', 'Future', 'On Hold', and 'Recurring' sections.&nbsp; To add a new section, click the 'Report' menu item at the top of your status list and select 'Sections'.&nbsp; In the popup window, click 'Add' to add a section.&nbsp; This will add a section titled 'New Section'.</p>
    <img id="Picture 26" src="/Images/Help/image075.png" />
    <p>
        From here you can rename the section to your liking.&nbsp; All sections can be removed, or renamed except&nbsp;'General Comments'.&nbsp; To rename a section, click the
        <img id="Picture 51" src="/Images/Help/image076.png" />button, make your change and click
        <img id="Picture 58" src="/Images/Help/image077.png" />
        To remove a section, click
        <img id="Picture 59" src="/Images/Help/image078.png" />
        Once deleted, you can always restore your section using the
        <img id="Picture 60" src="/Images/Help/image079.png">
        button. Additionally, all sections except 'General Comments' can be moved. To move a section, click
        <img id="Picture 61" src="/Images/Help/image080.png" />
        and drag the section to the appropriate place in the list.&nbsp; When you are done, click the 'Close Window' button and all changes will be applied. New sections will not appear on your status report until you add a task to them. To add a new task, go to "Add" from the menu at the top, and select "New" or "Existing" task, then select the new section.
    </p>

    <h3><a id="9.3"></a>9.3 Adding a Task</h3>
    <p>Once you have your sections setup, you will want to add a task.&nbsp; To add a task, first click the 'Add' option from the menu at the top of the page and select 'New Task'. You will then be prompted to select the section to add the task to.</p>
    <img id="Picture 63" src="/Images/Help/image081.gif" />
    <p>Select the name of the section this task goes in from the list provided. You will then need to name the task and give it a due date.</p>
    <p>Once you are done, click 'Go'.</p>
    <p>You can also add a new task by clicking on the name of a section on your status report, or right-clicking the name of a section on your status report and choosing &quot;Add New Task&quot;.</p>
    <p>It is also possible to add existing tasks to your status report. This is how you can get a task which you created through some other means onto your status report. You can either click Add then Existing Task and choose a section, or right-click a section name on your status report and choose Add Existing Task. In either case you will see a drop-down list with every task relevant to you listed. Choose the task you want and click Add.</p>

    <h3><a id="9.4"></a>9.4 Altering a Task</h3>
    <p>To change a task that has  already been created simply click on the area you want to change and start typing. This applies to the priority, and deadline sections. To add to the progress, either click on the text you want to reply to, or click the '...' to add a new line.</p>
    <img id="Picture 62" src="/Images/Help/image082.gif" />
    <br />

    <h3><a id="9.5"></a>9.5 Completing/Archiving Tasks</h3>
    <p>
        To complete a task, click the
        <img id="Picture 69" src="/Images/Help/image083.png">
        button in the far left column. This moves the task to the completed section, below the current section.
    </p>
    <p>If a task has more than one step, you will need to click the task name. That will open a window showing all the steps of that task. Check off each step then click Complete to complete the task.</p>

    <h3><a id="9.6"></a>9.6 Moving/Copying Tasks</h3>
    <p>To move a task to a different section, right click the task name, then select 'Copy Task' or 'Move Task'. You will then be presented with a dropdown list of reports and sections to move the task to.&nbsp; Select the appropriate report/section and click 'Go'.</p>
    <p>If you 'move' the task it will be removed from its current section, whereas if you 'copy', it will remain.&nbsp; Please note, this does not create an extra copy of the task, it just adds it to a different report or section.</p>

    <h3><a id="9.7"></a>9.7 Remove a Task</h3>
    <p>To remove a task from the report, first select the task by clicking in either the priority, task, or deadline column; then click the 'Remove' button under the 'Tools' menu.</p>
    <p>NOTE: Removing a task from a report does not delete the task from QProcess - any users assigned to the task will still see the task in My Tasks, Calendar, and Task Summary, and are still responsible for its completion.</p>

    <h3><a id="9.8"></a>9.8 Managing Reports</h3>
    <p>The status application allows you to maintain more than one status report.&nbsp; To create a new report, click the 'Add/Delete/Edit Reports' button under the 'Reports' menu.</p>
    <img id="Picture 72" src="/Images/Help/image084.gif" />
    <p>
        Here you will be able to add and remove any report. Click 'Add' to add a new report and use the
        <img id="Picture 71" src="/Images/Help/image085.gif" />
        button to name it appropriately.&nbsp; When you are done, click 'Close Window'. You will then be able to switch to the new report when you mouse over 'Change Report' under the 'Reports' menu. Remember that you will need to setup your sections for this report as well.
    </p>

    <h3><a id="9.9"></a>9.9 Viewing the Archive</h3>
    <p>At any point you may go back and look at your archived tasks using the 'Archive' button under the 'Reports' menu.</p>
    <img id="Picture 75" src="/Images/Help/image086.gif" />
    <p>Tasks can be recovered from the archive by clicking the green arrow to the left of the task name. Recovering the task from the archive causes it to reappear on the active status report - you will then need to provide a new due date for the task.</p>

    <h3><a id="9.10"></a>9.10 Exporting</h3>
    <p>There is a window for exporting status reports to Microsoft Office and is found under the "Tools" menu on both the "My Status" and "Inbox" tabs.</p>
    <img id="Picture 80" src="/Images/Help/image087.gif" />
    <p>Selecting this export option will bring up a new dialog window with several options for exporting reports to either Word or Excel.</p>
    <img id="Picture 78" src="/Images/Help/image088.gif" />
    <p>With these options, you can export multiple reports into a single document or spreadsheet, including archived reports if desired. Additionally, you may filter the reports for task due dates or comments using a specified date range that will apply to all selected reports. There is also a checkbox to exclude altogether the general comments section of each report if desired. To export one or more reports, simply click the checkbox next to each report name, specify additional options if desired, and click &quot;Go&quot;. QProcess will build the export and open it in either Excel or Word.</p>

    <h3><a id="9.11"></a>9.11 Emails</h3>
    <p>You can email your entire status report to your supervisors or to yourself using the 'Email All' button under the 'Tools' menu.&nbsp; Click the email button and you will be prompted for who the report should be sent to.</p>
    <img id="Picture 81" src="/Images/Help/image089.gif" />
    <p>Select the appropriate names, and click 'Go' to send the email.&nbsp; Please note that a list of updated status reports will be sent to your supervisor daily, so you do not necessarily&nbsp;need email the report for your supervisor to see the updates.</p>

    <h3><a id="9.12"></a>9.12 Emailing Comments</h3>
    <p>
        <img id="Picture 93" src="/Images/Help/image090.gif" />
        Email comments is similar to Email,&nbsp;but it only sends the comments you have made in the last hour. Email comments only sends comments that you have made, or those that you are replying to.&nbsp; Please remember that when you are making a reply, you must click on the comment that you are replying to before adding your comments. Using the '...' will not register a reply. You can tell which comments in the application are replies because they are indented.
    </p>
    <p>
        Comment:
        <img id="Picture 90" src="/Images/Help/image091.gif" />
        Reply:
        <img id="Picture 85" src="/Images/Help/image092.gif" />
    </p>
    <p>You can select specific comments to email, if you do not wish to email all comments made within the past hour. Uncheck the box labeled &quot;Send all available comments&quot;, and a popout box appears.</p>
    <img id="Picture 84" src="/Images/Help/image093.jpg" />
    <p>All comments that you have made within the past hour are listed. Check only those comments that you wish to email, and click Go.</p>

    <h3><a id="9.12.1"></a>9.12.1 Showing task details when emailing all comments</h3>
    <p>To display task details (notes and checklists) when sending a status report via email: select "email all" under the "tools" button and click "include details".</p>
    <img id="MS-1" src="/Images/Help/MS-1.png" />

    <h3><a id="9.13"></a>9.13 Controllers</h3>
    <p>You can share status reports with other users in order to cooperatively maintain one status. Open your status report and click 'Controllers' under the 'Reports' menu. Select the name of the person you want to share the status list with, and click 'Add'. To remove a controller, click the Delete icon next to the user's name.</p>
    <p>NOTE: Do not add a user as a controller who is already listed as a supervisor or interested party on the report. A single user can only be a controller or a supervisor/interested party on a report, not both. To remove a user as a supervisor/interested party, send an email to <a href="mailto:<%=GradingEmail %>"><%=GradingEmail %></a> (see <a href="#9.1">9.1: Supervisors</a>)</p>

    <h3><a id="9.14"></a>9.14 Highlighting/View Deleted</h3>
    <p>Any comments added since the selected date are highlighted - the colors are based on the commenter's role (supervisor, interested party, controller). The default date is one day prior to today. Changing this date will cause the report to automatically refresh.</p>
    <img id="Picture 96" src="/Images/Help/image094.jpg" />
    <p>In addition, any tasks deleted since the selected date are shown, with the tag &quot;DELETED&quot; next to the task name. Deleted tasks cannot be altered or commented on. Deleted tasks can be recovered by clicking the green arrow to the left of the task name.</p>
    <img id="Picture 95" src="/Images/Help/image095.jpg" />
    <br />

    <h3><a id="9.15"></a>9.15 Hide Tasks without Comments</h3>
    <p>By default, all tasks are shown on the status report. Check the box labeled &quot;Hide tasks without comments due after&quot;, and any tasks that have no comments, and are due after the specified date, will be hidden.</p>
    <img id="Picture 100" src="/Images/Help/image096.jpg" />
    <p>NOTE: If you add a new task, and it does not immediately appear on your report, make sure that this checkbox is unchecked - you may be inadvertently hiding your new task if this box is checked.</p>

    <h3><a id="9.16"></a>9.16 Show Tasks Assigned To Specific Users</h3>
    <p>By default, all assignees' tasks are shown on the status report. Change the value in the dropdown list labeled &quot;Show tasks assigned to&quot;, and only tasks assigned to the selected user/group will be shown.</p>
    <img id="Picture 112" src="/Images/Help/image097.jpg" />
    <br />

    <h3><a id="9.17"></a>9.17 Timeline</h3>
    <p>Clicking the Timeline button will show a listing of all upcoming tasks and their associated due dates.</p>

    <h3><a id="9.18"></a>9.18 Toggle Assignees</h3>
    <img id="Picture 123" src="/Images/Help/image098.png">
    <p>Clicking View/Assignees will toggle the visibility of the Assignees column on and off.</p>

    <h3><a id="9.19"></a>9.19 Printing</h3>
    <p>Under the Print menu, there are four options for print output:</p>
    <img id="Picture 127" src="/Images/Help/image099.png" />
    <p>&quot;Print&quot; will cause the standard print dialog to appear - the report will be printed using the default print settings if no options are changed.</p>
    <p>&quot;Print Large&quot; optimizes the print output for 11&quot; x 17&quot; paper. Be sure to select a printer that supports 11&quot; x 17&quot; printing, and that you specifically select that paper size for the printer.</p>
    <p>&quot;Print B&amp;W&quot; and &quot;Print Large B&amp;W&quot; function the same way as the first two options, except that the resulting text output is optimized for black and white printing. All general comments and active tasks are printed in black text, while any completed tasks are printed in gray text.</p>
    <p>With all four of these print options, the resulting output is automatically reformatted so that the task information and its associated comments are presented on separate rows. This allows for greater readability, especially for tasks with extensive comments.</p>
    <img id="Picture 125" src="/Images/Help/image100.gif" />
    <br />

    <h3><a id="9.20"></a>9.20 Searching</h3>
    <p>To search for specific words in a status report, press <b>[Ctrl] + F</b>. A search box will open.</p>
    <img id="Picture 130" src="/Images/Help/image101.png" />
    <p>Type in the word or words you want to search for, then click Next. If your search terms are found, they will be highlighted on the status report.</p>
    <img id="Picture 132" src="/Images/Help/image102.png">
    <br />

    <h3><a id="9.21"></a>9.21 Adding Links to Comments</h3>
    <p>
        It's possible to add links to documents within a QProcess comment. Click the Add link button
        <img id="Picture 133" src="/Images/Help/image103.gif" />
    </p>
    <p>In the window that pops up, choose the file you want to link. Be sure the file is in a location that people reading the comment can access, such as the P: drive. Don't link to documents on your C: or U: drives, nobody else can access those but you.</p>

    <h3><a id="9.22"></a>9.22 Bulk Update</h3>
    <p>There is a bulk update feature under Tools -&gt; Bulk Update. You can use this tool to move soft deadlines and/or add comments to a batch of tasks on a status report at once.</p>
    <img id="Picture 135" src="/Images/Help/image104.gif" />
    <p>After you have chosen a new soft deadline or entered a comment, you can choose which tasks on the report to apply the soft deadline or comment to.</p>
    <img id="Picture 134" src="/Images/Help/image105.gif" />
    <br />

    <h3><a id="9.23"></a>9.23 Response Requested</h3>
    <p>When you make a comment on a task, you can click the Response Requested button to send an immediate e-mail to other people on the status report. The e-mail will contain only the comment(s) you just made on that task.</p>
    <img id="Picture 136" src="/Images/Help/image106.gif" />

    <h3><a id="9.24"></a>9.24 Switching Between Reports</h3>
    <p>To move between reports, mouse over Report, then Change Report. You will see a list of all your status reports from both the My Status and My Inbox tabs. Click on any report to view that report.</p>
    <img id="Picture 138" src="/Images/Help/image107.png">
    <br />

    <h3><a id="9.25"></a>9.25 Reassign a Task</h3>
    <p>You can reassign a task (or request to reassign a task if you are not the controller) from a status report. Under the Assignees column, click Reassign Task or Request to Reassign. You will then see a list of people and groups. Choose the new assignee and click Save. If you are not a controller of the task, the task's controller(s) will receive an e-mail that you have requested to reassign the task.</p>

    <h3><a id="9.26"></a>9.26 My Status Search</h3>
    <p>
        By clicking the "search page" button at the top right of the "My Status" page, the search bar will appear. 
Click on the search bar, and your 10 most recent searches will be suggested.
You can also click on one of the suggested words and it will populate and search for you. 
You can filter/sort by a specific date range, today, this week, or this month.
You can include archived results by checking the box "include archived."
As you begin typing, results will be returned based on what you have typed so far. This will return both task names, and items matching within the checklist. 
Then the matched words will appear highlighted in red.
    </p>
    <img id="Picture 252" src="/Images/Help/image252.png">
    <p>After searching a word, a message appears to alert you of how many instances of that name were found.</p>
    <img id="Picture 253" src="/Images/Help/image253.png">
    <p><b>When selecting "Advanced Matching" Boolean Operators can be used.</b></p>
    <p>Selecting "must match all words" - when searching more than one word, this option will return only tasks that contain all of the words entered in the search textbox.</p>
    <p>Selecting "can match any word" - when searching more than one word, this option will return tasks that contain <i>any</i> of the words entered in the textbox. For example, searching <b>"Q Family Office"</b> will return tasks with <b>Q, Family,</b> or <b>Office</b></p>
    <p>Selecting "advanced matching" - enables the use of Boolean operators (such as <b>AND, OR, </b>and <b>NOT</b>) to create more precise search queries.</p>
    <p>The search string <b>Final AND (Test OR QProcess)</b></p>
    <ul>
        <li><b>AND:</b> The AND operator requires the terms on either side of it to both exist, but it searches for them independently.</li>
        <li><b>OR:</b> The OR operator requires at least one of the two search terms on either side to match.</li>
        <li><b>NOT:</b> The NOT operator excludes any task matching the search term after it.</li>
    </ul>
    <p>Note order of operations matters, the use of parenthesis is important when using multiple Boolean operators, for example: match all tasks that included the word "Final" and either the word "Test" or the word "QProcess", you can use parentheses to guide the search behavior.</p>
    <ul>
        <li>Some more helpful hints using Boolean operators
        <ul>
            <li>These search terms are <i>not</i> case sensitive</li>
            <li>Multi-word terms <i>must</i> be double quotes, regardless of anything else in the search. "Q Family Office"</li>
            <li>Semicolons - <b>;</b> - cannot appear anywhere in the search criteria</li>
            <li>You <i>can</i> search "and", "or", and "not", and for tasks containing parentheses; simply make sure they're in double-quotes. <b>"Complete and Final Test (not intermediate)"</b> will match any task with exactly that sequence of characters somewhere in its title, checklist or comments.</li>
        </ul>
        </li>
    </ul>
    <p style="color:red">Please note: Search is refreshed hourly, so new tasks may not appear in search results for up to an hour after task creation.</p>
    <br />
    <br />
    <!-- ============================================================
					10. MY INBOX
	 ============================================================ -->
    <h2><a id="10"></a>10. My Inbox</h2>
    <p>If you are a supervisor or an interested party on at least one status report, you will see the My Inbox tab, in addition to the My Status tab. To be added as a supervisor or interested party, send a request via email to <a href="mailto:<%=GradingEmail %>"><%=GradingEmail %></a>.</p>

    <h3><a id="10.1"></a>10.1 The Inbox</h3>
    <p>The Inbox view consists of two lists.</p>
    <img id="Picture 146" src="/Images/Help/image108.gif" />
    <p>The top list is the list of status reports that you have not yet read. Once read (i.e. the 'Mark Read' button is clicked on the report), the status report moves to the bottom 'Read' list. The inbox shows the name of the status report, along with when it was last updated and when you last read it. To view a status report, simply click anywhere on the row displaying the details of the report.</p>
    <img id="Picture 145" src="/Images/Help/image109.gif" />
    <p>You can filter your inbox based on three criteria. Click the 'Supervisor' link in the menu to see all reports you are listed as a supervisor on. Click the 'Interested Party' link to see all reports you are listed as an interested party on. And click the 'My Favorites' link to see your favorites. You can add or remove a status report from your favorites by clicking on the star next to the name of the status report on your inbox view.</p>

    <h3><a id="10.2"></a>10.2 Adding Comments</h3>
    <p>Once you are viewing a status report, you can make comments as needed in the progress area the same way you would if this was your own status report.&nbsp; Just click on the comment you are replying to, or use the ellipses to add a new line.</p>
    <img id="Picture 144" src="/Images/Help/image082.gif" />
    <br />

    <h3><a id="10.3"></a>10.3 Highlighting/View Deleted</h3>
    <p>This works the same way as on the My Status tab - see <a href="#9.14">section 9.14</a>.</p>

    <h3><a id="10.4"></a>10.4 Hide Tasks Without Comments</h3>
    <p>This works the same way as on the My Status tab - see <a href="#9.15">section 9.15</a>.</p>

    <h3><a id="10.5"></a>10.5 Show Tasks Assigned To Specific Users</h3>
    <p>This works the same way as on the My Status tab - see <a href="#9.16">section 9.16</a>.</p>

    <h3><a id="10.6"></a>10.6 Mark a Status Report Read</h3>
    <p>
        <img id="Picture 143" src="/Images/Help/image110.gif" />
        To mark a status report as read, click the 'Mark Read' button at the top of the page. This will move the status report to the 'Read' part of your inbox.
    </p>

    <h3><a id="10.7"></a>10.7 Emailing Comments</h3>
    <p>This works the same way as on the My Status tab - see <a href="#9.12">section 9.12</a>.</p>
    <p>When emailing comments, to immediately mark the report as read and return to the inbox, click the &quot;Email, Mark Read, Go To Inbox&quot; button. Click the &quot;Go&quot; button to remain on the status report after emailing the comments.</p>

    <h3><a id="10.8"></a>10.8 Inbox Navigation</h3>
    <p>
        <img id="Picture 142" src="/Images/Help/image111.gif" />
        To return to your inbox, click the 'Inbox' button at the top of the page.
    </p>

    <h3><a id="10.9"></a>10.9 Take Control</h3>
    <p>All supervisors have the ability to take control of tasks on the My Inbox tab when looking at a report. If the controller on a task is not specifically you and only you, you will see a &quot;Take Control&quot; button next to that task.</p>
    <p>Be careful when using this feature! It was designed so supervisors can take control of tasks instead of their employees being controllers on their own tasks. If more than one supervisor is a controller on a task and you click it, you will remove the other supervisor(s) as controllers.</p>

    <h3><a id="10.10"></a>10.10 Manage Emails</h3>
    <p>If you click on Tools -&gt; Manage Emails, you can decide what alert e-mails you automatically receive. </p>
    <img id="Picture 141" src="/Images/Help/image112.gif" />
    <p>There are options for overdue items, unread reports, and due date changes.</p>
    <img id="Picture 140" src="/Images/Help/image113.gif" />
    <p><b>When selecting "Advanced Matching" Boolean Operators can be used.</b></p>
    <p>Selecting "must match all words" - when searching more than one word, this option will return only tasks that contain all of the words entered in the search textbox.</p>
    <p>Selecting "can match any word" - when searching more than one word, this option will return tasks that contain <i>any</i> of the words entered in the textbox. For example, searching <b>"Q Family Office"</b> will return tasks with <b>Q, Family,</b> or <b>Office</b></p>
    <p>Selecting "advanced matching" - enables the use of Boolean operators (such as <b>AND, OR, </b>and <b>NOT</b>) to create more precise search queries.</p>
    <p>The search string <b>Final AND (Test OR QProcess)</b></p>
    <ul>
        <li><b>AND:</b> The AND operator requires the terms on either side of it to both exist, but it searches for them independently.</li>
        <li><b>OR:</b> The OR operator requires at least one of the two search terms on either side to match.</li>
        <li><b>NOT:</b> The NOT operator excludes any task matching the search term after it.</li>
    </ul>
    <p>Note order of operations matters, the use of parenthesis is important when using multiple Boolean operators, for example: match all tasks that included the word "Final" and either the word "Test" or the word "QProcess", you can use parentheses to guide the search behavior.</p>
    <ul>
        <li>Some more helpful hints using Boolean operators
        <ul>
            <li>These search terms are <i>not</i> case sensitive</li>
            <li>Multi-word terms <i>must</i> be double quotes, regardless of anything else in the search. "Q Family Office"</li>
            <li>Semicolons - <b>;</b> - cannot appear anywhere in the search criteria</li>
            <li>You <i>can</i> search "and", "or", and "not", and for tasks containing parentheses; simply make sure they're in double-quotes. <b>"Complete and Final Test (not intermediate)"</b> will match any task with exactly that sequence of characters somewhere in its title, checklist or comments.</li>
        </ul>
        </li>
    </ul>
    <br />
    <h3><a id="10.11"></a>10.11 My Inbox Search</h3>
    <p>
        You will also be able to search through any status report that appears in your inbox by first clicking on and navigating to it..
        By clicking the "search page" button at the top right of the "Inbox" page, the search bar will appear. 
        Click on the search bar, and your 10 most recent searches will be suggested.
        You can also click on one of the suggested words and it will populate and search for you. 
        You can filter/sort by a specific date range, today, this week, or this month.
        You can include archived results by checking the box "include archived."
        As you begin typing, results will be returned based on what you have typed so far. This will return both task names, and items matching within the checklist. 
        Then the matched words will appear highlighted in red. 
    </p>
    <img id="Picture 254" src="/Images/Help/image254.png">
    <p>After searching a word, a message appears to alert you of how many instances of that name were found.</p>
    <img id="Picture 255" src="/Images/Help/image255.png">
    <p style="color:red">Please note: Search is refreshed hourly, so new tasks may not appear in search results for up to an hour after task creation.</p>

    <h3><a id="10.12"></a>10.12 Supervisor Dashboard</h3>
    <p>This is a feature that provides supervisors with Key Performance Indicators (KPIs) related to how employees are engaging with the app relative to their coworkers. </p>

    <h3><a id="10.12.1"></a>10.12.1 Main View</h3>

    <p>Access the main page by clicking "Supervisor Dashboard" at the top.</p>
    <img id="SD-1" src="/Images/Help/sd-1.png"/>

    <p>Metrics can be hidden by clicking the color you wish to hide.</p>
    <img id="SD-2" src="/Images/Help/sd-2.png"/>

    <p>Hover over a bar to reveal data at a quick glance.</p>
    <img id="SD-3" src="/Images/Help/sd-3.png"/>

    <p>Select "Choose Employees" button to reveal all people you supervise. If they supervise additional people, 
        you can toggle with the "Directly Supervised" button to see this. Filter individuals by the groups they 
        belong to by selecting from the "group" dropdown.</p>
    <img id="SD-4" src="/Images/Help/sd-4.png"/>

    <p>To see KPIs by individual, click the bar graph associated with the desired name.</p>
    <img id="SD-5" src="/Images/Help/sd-5.png"/>

    <p>The user dashboard appears with gauges comparing KPI's to other users in the company, a list of status reports 
        they have, all active assignments, and groups they are a member of.</p>
    <img id="SD-6" src="/Images/Help/sd-6.png"/>

    <p>Note some assignments appear as "redacted" for the task name. This is for confidentiality reasons as these are 
        tasks controlled by someone other than you. You can also copy, export as Excel/CSV, or print the assignment, 
        group, and status KPI's.</p>
    <img id="SD-7" src="/Images/Help/sd-7.png"/>    

    <br />
    <br />
    <!-- ============================================================
					11. PRIORITIES
	 ============================================================ -->
    <h2><a id="11"></a>11. Priorities</h2>

    <h3><a id="11.1"></a>11.1 The Priority List</h3>

    <p>The priority list is a way to communicate the tasks that you are working on and their priorities to your supervisor, and your supervisor to make adjustments and communicate them back to you.</p>

    <h3><a id="11.2"></a>11.2 Adding Tasks</h3>
    <p>To add a task to your priority list, right-click your name and choose Add Tasks. You will see a list of all your upcoming tasks with checkboxes next to them. Put checks next to the tasks you want to add then click &quot;All Checked&quot; in the bottom-left corner of the screen. You can also click &quot;All Due Today&quot; or &quot;All Due This Week&quot; as a shortcut. If you want to never see a task in the list, put a check next to only it and click &quot;Exclude Selected Tasks From List&quot;. BE CAREFUL when you do this, you cannot get that task back on the list.</p>
    <p>You can also right-click any task assigned to you on the My Status tab and choose Add to Priorities. This is an efficient way to add tasks to your priority list from your personal status report.</p>

    <h3><a id="11.3"></a>11.3 Removing Tasks</h3>
    <p>To remove a task from your priority list, click and hold it. The task will highlight yellow and you will see a trash can icon at the bottom of your task list. Drag the task onto the trash can icon and it will be removed from your priority list.</p>

    <h3><a id="11.4"></a>11.4 Clearing the List</h3>
    <p>If you want to quickly remove all tasks from your priority list and start over, you can right-click your name and choose &quot;Clear List&quot;. This will immediately remove all tasks from your priority list.</p>

    <h3><a id="11.5"></a>11.5 Emailing Priorities</h3>
    <p>To e-mail your priorities to your supervisor, click the &quot;Email Priorities&quot; button toward the top-right corner of the Priorities tab. You will see a list of names that includes yourself, your supervisor(s), and Geoffrey. Check the boxes next to who you want to send the e-mail to. There is a large text area where you can type general comments to go along with your priority list. To send the e-mail, click &quot;Send Email&quot;.</p>

    <h3><a id="11.6"></a>11.6 Supervisor Features</h3>
    <p>Supervisors have an additional set of features that normal users don't see. They primarily deal with the ability of supervisors to have multiple priority lists, and each priority list can contain the priorities of more than one person. Features such as adding tasks or e-mailing priority lists work the same for supervisors as they do for other people.</p>
    <img id="Picture 139" src="/Images/Help/image114.gif" />
    <br />

    <h3><a id="11.6.1"></a>11.6.1 Adding People to Lists</h3>
    <p>The &quot;Add Names&quot; button lets you add people to a priority list. You will see a list of names with checkboxes. Check the names you want to add and click &quot;Add&quot;.</p>

    <h3><a id="11.6.2"></a>11.6.2 Removing People from Lists</h3>
    <p>When you hover your mouse over people's names on the priority list, you will see a crosshairs icon. Click and hold this and you will see a large trash can icon. Drag the person's name to the trash can icon and their priority list will be removed from the list you are adding.</p>

    <h3><a id="11.6.3"></a>11.6.3 Reorganizing Priority Lists</h3>
    <p>To reorder the people on a priority list, hover your mouse over a person's name. Click and hold the crosshairs icon that appears to the left of their name. The priorities for each person will collapse down so you only see names. Drag the crosshairs up and down to reorder the people on the priority list.</p>

    <h3><a id="11.6.4"></a>11.6.4 Switching Priority Lists</h3>
    <p>To switch priority lists, click the &quot;Switch Priority Lists&quot; button at the top of the Priorities tab. You will see all the priority lists you manage listed out. You can choose any of these to view it.</p>

    <h3><a id="11.6.5"></a>11.6.5 Creating Priority Lists</h3>
    <p>Click the the &quot;Switch Priority Lists&quot; button at the top of the Priorities tab. At the bottom of the list of people, you'll see a text box labeled &quot;New&quot;. Fill in a name and press <b>[Enter]</b>. A new blank priority list will be created with the name you provided. You can then click the &quot;Add Names&quot; button to add people to the priority list.</p>

    <h3><a id="11.6.6"></a>11.6.6 Deleting Priority Lists</h3>
    <p>Switch to the priority list you want to delete then click the &quot;Delete Priority List&quot; button at the top of the Priorities tab. A confirmation box will pop up. Click &quot;Delete&quot; to delete the priority list.</p>
    
    <h3><a id="11.7"></a>11.7 Sort Priority List by due date</h3>
    <p>Clicking "prioritize by date" will reset your priority tasks in order of closest due date.</p>
    <img id="PL-1" src="/Images/Help/PL-1.png" />

    <h3><a id="11.8"></a>11.8 Priority History Comments</h3>
    <p>You can see and reply to historical comments on your Priority List. This can be done 2 different ways.</p>
    <ul>
        <li>
            <p>Individually expand or minimize each task by clicking the + next to tasks with old comments. Or click the large + at the top to expand out all tasks with old comments. From there you can reply to existing comments.</p>
        </li>
    </ul>
    <img id="PL-2" src="/Images/Help/PL-1.png" />

    <!-- ============================================================
		12. TIME ZONES
    ============================================================ -->
    <h2><a id="12"></a>12. Time Zones In <%= QProcess.Configuration.AppSettings.AppName %></h2>
    <p>
        <%= QProcess.Configuration.AppSettings.AppName %> is "time-zone aware"; the app knows your device's current time zone, and will seamlessly convert 
        the dates and times shown in the app to that local time. You can also specify the time zone to use for 
        scheduling when creating or modifying a task. Whether you're traveling or just need to coordinate with users 
        in different parts of the world, this feature ensures that your tasks are always scheduled accurately, no 
        matter where you are.  
    </p>
    <h3><a id="12.1"></a>12.1 Your Time Zone</h3>
    <p>
        The current time zone used by <%= QProcess.Configuration.AppSettings.AppName %> is displayed at the bottom 
        of the screen, next to the globe icon. Mobile users can find it at the bottom of the main menu by tapping 
        the "hamburger" icon in the upper right. 
    </p>
    <p>
        To avoid ambiguity, time zones are displayed using IANA region/city 
        names, so for instance, the U.S. Central Time region is called "America/Chicago".
    </p>
    <img id="Time Zone Display" src="/Images/Help/tz-1.png" />
    <p>
        Your time zone will default to the one in your computer or mobile device OS settings, which in most cases 
        will match your physical location and (on portable devices) will follow you as you travel. You can override 
        this setting within <%= QProcess.Configuration.AppSettings.AppName %> if you prefer to view times in a different 
        zone than the one reported by your device.
    </p>
    <p>
        All times shown in the application will be displayed in your currently-selected time zone. Different users in 
        different time zones can thus see the same task as being due at different local times, but these will be the 
        same "moment" in time. For example, a task due at 7:00 PM in Chicago would be due at 8:00 PM in New York, and 
        at 5:00 PM in Los Angeles.
    </p>
    <h3><a id="12.2"></a>12.2 Time Zone Map</h3>
    <p>
        To change the time zone used by <%= QProcess.Configuration.AppSettings.AppName %> to display your tasks, simply click this time zone display, 
        and you will be shown a map with the available global time zones. 
    </p>
    <img id="Time Zone Map" src="/Images/Help/tz-2.png" />
    <p>
        To select a new time zone, you may choose it from the drop-down in the upper-left corner, 
        or click the location on the world map. Your currently-selected time zone will be displayed in the 
        drop-down, and highlighted on the map. The region underneath your mouse cursor 
        will be highlighted in a different color (depending on the exact version of your app); click to select that region. 
    </p>
    <img id="Time Zone Map Highlight" src="/Images/Help/tz-3.png" />
    <p>
        The area above the map also contains a row of buttons corresponding to the most common time zones for users of 
        this app. Simply click to select that time zone.
    </p>
    <img id="Time Zone Buttons" src="/Images/Help/tz-4.png" />
    <p>
        When you have made your selection, remember to click the "Save" button in the bottom right of the map display. 
        The map will clear and the page will refresh to update any times displayed.
    </p>
    <img id="Time Zone Override" src="/Images/Help/tz-5.png" />
    <p>
        If you have overridden your local time zone, the selected time zone will show in red. 
        <%= QProcess.Configuration.AppSettings.AppName %> will continue to use this time zone, even 
        if you physically travel to another region. To clear this override, simply select your current location as 
        your preferred time zone; the app will then "follow" you as you travel. You can do this quickly by clicking 
        the "Client Time Zone" displayed at the bottom right of the map.
    </p>
    <h3><a id="12.3"></a>12.3 Scheduling Tasks</h3>
    <p>
        When creating or editing a complex task, you can select the specific time zone for the task's due date and time.
        This allows you to easily specify a "due time" for a task assigned to a person in a different time zone, 
        without having to manually calculate and apply the time difference between your zone and theirs. 
    </p>
    <p>
        Time zone selection is available in the "Complex Task" setup screen for new tasks. From the "New Task" tab,
        enter the basic task information, then select the "Customize (Complex Task)" radio button and click "Create". 
        You will see a time zone drop-down in the Scheduling section of the next screen.
    </p>
    <img id="Scheduling Task Section" src="/Images/Help/tz-6.png" />
    <p>
        This time zone will default to your current selected time zone. To change it, click the down arrow to expand 
        the drop-down and find your preferred region. Common time zones used by the company will display at the top 
        of the list.
    </p>
    <img id="Scheduling Time Zone Dropdown" src="/Images/Help/tz-7.png" />
    <p>
        This time zone will default to your current selected time zone. To change it, click the down arrow to expand 
        the drop-down and select your choice. Common time zones used by the company will display at the top of the list.
    </p>
    <p>
        This same drop-down is also available for existing tasks in the Manage Tasks tab. Select and load your task as 
        normal, and the drop-down will be shown in the Scheduling group of the Assignment section. When editing here, 
        don't forget to click "Save" in the Scheduling groupbox to save changes.
    </p>
    <h3><a id="12.4"></a>12.4 Bulk Time Zone Conversion</h3>
    <p>
        To assist in the conversion from <%= QProcess.Configuration.AppSettings.AppName %>'s older single-timezone model,
        a tool is available allowing easy conversion of the time zone for the schedules of all tasks you control. The page 
        can be found at <a href="<%= QProcess.Configuration.AppSettings.SiteRoot %>TimeZoneConversion.aspx"><%= QProcess.Configuration.AppSettings.SiteRoot %>TimeZoneConversion.aspx</a>.
        Instructions for use can be found on that page.
    </p>

    <!-- ============================================================
			13. MOBILE VERSION
     ============================================================ -->

    <h2><a id="13"></a>13. Mobile Version of <%= QProcess.Configuration.AppSettings.AppName.ToUpperInvariant()%></h2>
    <h3><a id="13.1"></a>13.1 Navigation</h3>
    <p>
        The mobile version of the application will display by default on mobile device browsers (any browser identifying itself 
        as an "Android", "iPhone" or "iPad" device). You can also switch to the mobile version from any browser or device 
        using the "Mobile View" link in the footer of the app. On larger mobile devices, you may wish to use the desktop
        version of the application instead; if so, there is a "Desktop View" option in the mobile version's main menu. 
        The application will remember your preference for the life of your browser session, however if you switch to another app
        and leave the site inactive for an extended time, it may revert to the default for your device type.
    </p>
    <p>To move between tabs on the mobile view, utilize the "waffle" icon at the top right of your screen.</p>
    <img src="/Images/Help/nav1.png" />
    <p>
        After selecting the waffle, all of your typical tabs will be listed, with the addition of the "help", "search", 
    and "Desktop View" options.
    </p>
    <img src="/Images/Help/nav2.png" />
    <h3><a id="13.2"></a>13.2 My Tasks</h3>
    <p>
        The mobile My Tasks view has a slightly different layout of checklist information to accomodate the narrower screen.
    Functionally, the primary difference between the desktop and mobile view is that you are unable to export your task list or 
    individual tasks to Excel via the mobile app.
    </p>
    <h3><a id="13.3"></a>13.3 Calendar</h3>
    <p>The calendar tab on the mobile version shows you the month at a glance, as well as the current day's tasks.</p>
    <img src="/Images/Help/cal1.png" />
    <p>
        The mobile version shows only one day's tasks, not the whole week. Select the "Legend" header to see the key, which will 
    hide the Calendar control to make room. After expanding the legend you have the option to filter the view similarly to the 
    desktop version (including "Tasks I Control" and views for supervised employees).     
    </p>
    <img src="/Images/Help/cal2.png" />
    <h3><a id="13.4"></a>13.4 Manage Tasks</h3>
    <p>The mobile version has the same features with a slightly different view from the desktop.</p>
    <img src="/Images/Help/manage1.png" />
    <p style="color:red">Please note: Search is refreshed hourly, so new tasks may not appear in search results for up to an hour after task creation.</p>
    <h3><a id="13.5"></a>13.5 New Task</h3>
    <p>
        The mobile version has the same features with a slightly different view from the desktop. 
    On some devices, you must scroll down to see the green "Create" button.
    </p>
    <img src="/Images/Help/new1.png" />
    <img src="/Images/Help/new2.png" />
    <h3><a id="13.6"></a>13.6 Change Request</h3>
    <p>
        The mobile version has the same features with a different layout from the desktop. 
    The "cancel" and "change" buttons are green in this view.
    </p>
    <img src="/Images/Help/change.1.png" />
    <h3><a id="13.7"></a>13.7 Reports</h3>
    <p>The mobile version has the same features with a slightly different layout from the desktop.</p>
    <img src="/Images/Help/reports.1.png" />
    <h3><a id="13.8"></a>13.8 Groups</h3>
    <p>
        The mobile version of Groups has the same features with a slightly different view from the desktop. 
    In order to see all columns in the table you must scroll horizontally.
    </p>
    <img src="/Images/Help/group.1.png" />
    <img src="/Images/Help/group.2.png" />
    <h3><a id="13.9"></a>13.9 Task Summary</h3>
    <p>
        The mobile version has the same features with a slightly different layout from the desktop. 
        In order to change the dates under "Bulk N/A tasks" you scroll rather than selecting from a calendar.
    </p>
    <img src="/Images/Help/tasksum1.png" />
    <h3><a id="13.10"></a>13.10 My Status</h3>
    <p>
        The mobile version functions differently from the desktop. Mobile does not, at this time, have the full
        "toolbar" of menu options from Desktop, and the available features are reduced. 
        You are able to switch between multiple status reports by tapping "Change Report".  
        You may also add new or existing tasks using the "Add Tasks" button, and you may email comments 
        using the "Email" button.
    </p>
    <img src="/Images/Help/mystat1.png" />
    <h3><a id="13.11"></a>13.11 Priorities</h3>
    <p>The mobile version has most of the same features with a different view from the desktop.</p>
    <img src="/Images/Help/priorities.png" />
    <p>
        The buttons typically found in the top ribbon are instead located under the setting (gear) icon at the top 
    left of the screen, including the ability to email your priorities and to create and manage additional priority lists.
    </p>
    <img src="/Images/Help/priorities1.png" />
    <p>You do not, at this time, have the ability to change font size. </p>
    <img src="/Images/Help/priorities2.png" />
    <h3><a id="13.12"></a>13.12 Help</h3>
    <p>
        Aside from not being located at the bottom of the page, the mobile version of Help functions identically, 
    with a slight change to the styling of the Table of Contents.
    </p>
    <h3>13.13 Search</h3>
    <p>The mobile version of Search looks and functions the same as the desktop.</p>
    <img src="/Images/Help/search1.png" />
    <h3><a id="13.13"></a>13.13 Miscellaneous</h3>
    <p>
        At this time there is not an option to access various tabs found at the bottom of the desktop version such as: 
    Vacation, bulk assignments, view groups, automations, or preferences. Additional administrator-level features 
    normally found here are also not available in the mobile version.
    </p>
    <img src="/Images/Help/help1.png" />


    <!-- ============================================================
				14. MISC STATUS REPORT TIPS AND INFO
	 ============================================================ -->
    <h2><a id="14"></a>14. Miscellaneous Status Report Tips and Info</h2>

    <h3><a id="14.1"></a>14.1 General Comments</h3>
    <p>General Comments will be archived off after 15 comments have been made.</p>

    <h3><a id="14.2"></a>14.2 Show/Hide</h3>
    <p>
        After 2 weeks, a comment will no longer be displayed by default.&nbsp; You will need to click the
        <img id="Picture 148" src="/Images/Help/image115.gif" />
        button to view these comments, and the
        <img id="Picture 147" src="/Images/Help/image116.gif" />
        button to hide them again.
    </p>

    <h3><a id="14.3"></a>14.3 Fonts</h3>
    <p>To change the font displayed on your status report, use the 'Change Fonts' button under the 'Tools' menu.&nbsp; Please note that this only applies to how it looks in the web application.&nbsp; Emails will continue to use the large font.</p>

    <h3><a id="14.4"></a>14.4 Searching Status Reports</h3>
    <p>To search for specific words in a status report, press <b>[Ctrl] + F</b>. A search box will open.</p>
    <img id="Picture 152" src="/Images/Help/image101.png" />
    <p>Type in the word or words you want to search for, then click Next. If your search terms are found, they will be highlighted on the status report.</p>
    <img id="Picture 151" src="/Images/Help/image102.png" />
    <br />

    <h3><a id="14.5"></a>14.5 Bulk Assignments</h3>
    <p>The Bulk Assignments tool is useful if you are going on vacation and need someone to cover your tasks while you are out. You can access the tool by clicking the Bulk Assignments link at the bottom of QProcess </p>
    <img id="Picture 153" src="/Images/Help/image117.gif" />
    <p>At the top of the page, choose who will be covering your tasks in the Add/Remove drop-down. You can put a comment like &quot;Ken is covering my tasks while I'm out&quot;.</p>
    <img id="Picture 155" src="/Images/Help/image118.gif" />
    <p>Then, in the list of tasks on the page check the boxes next to all the tasks that person will be covering for you.</p>
    <img id="Picture 154" src="/Images/Help/image119.gif" />
    <p>Finally, back at the top of the page click &quot;Add Assignment&quot;. For any tasks you control, the new assignee will be added. For tasks you do not control, a change request will be sent to the controller(s). That's the purpose of the Comment field--that message gets sent to the task controller(s) along with the change request.</p>
    <p>You'll notice that the tasks you checked become highlighted yellow. This is so when you get back from vacation you can easily remove the person who was covering your tasks. Just check the boxes next to all the yellow tasks, choose the person who was covering your tasks, then click &quot;Remove Assignment&quot;. The same process happens but in reverse--requests are sent for tasks you do not control to remove the person who was covering your tasks.</p>

    <h3><a id="14.6"></a>14.6 Comments from Emails</h3>
    <p>When you send an e-mail from QProcess using Response Requested, Email Comments, Email Today's Comments, or Email Priorities, you'll see there's a &quot;Reply&quot; section in the e-mail.</p>
    <img id="Picture 162" src="/Images/Help/image120.gif" />
    <p>This section allows QProcess to capture comments directly from the e-mail and save them on your status report(s).</p>
    <img id="Picture 161" src="/Images/Help/image121.gif" />
    <br />
    <img id="Picture 160" src="/Images/Help/image122.gif" />
    <p>If you want, you can have a conversation back and forth within that Reply box. In order for QProcess to know where each new reply begins, you must use a double equals sign (==) or hit Enter to make Outlook put your name in brackets as a divider.</p>
    <img id="Picture 159" src="/Images/Help/image123.gif" />
    <br />
    <img id="Picture 158" src="/Images/Help/image124.gif" />
    <p>Each new reply indents on the status report. You can continue conversing back and forth as long as you want.</p>
    <img id="Picture 157" src="/Images/Help/image125.gif" />
    <br />
    <img id="Picture 156" src="/Images/Help/image126.gif" />
    <br />

    <!-- ============================================================
			15. Global Search
         ============================================================ -->

    <h2><a id="15"></a>15. Global Search</h2>
    <p>
        You can access the global search feature from any of the tabs at the top.
    Once selected, a new window will open up
    </p>
    <img id="Picture 256" src="/Images/Help/image256.png" />
    <br />
    <p>You can filter/sort by a specific date range, today, this week, or this month.</p>
    <img id="Picture 257" src="/Images/Help/image257.png" />
    <br />
    <p>
        Selecting "must match all words" - when searching more than one word, this option will return only tasks that contain all of the words entered in the search textbox.
    </p>
    <p>
        Selecting "can match any word" - when searching more than one word, this option will return tasks that contain <i>any</i> of the words entered in the textbox. For example, searching <b>"Q Family Office"</b> will return tasks with <b>Q, Family,</b> or <b>Office</b>
    </p>
    <p>
        Selecting "advanced matching" - enables the use of Boolean operators (such as <b>AND, OR, </b>and <b>NOT</b>) to create more precise search queries.
    </p>
    <p>
        The search string <b>Final AND (Test OR QProcess)</b>
    </p>
    <ul>
        <li>
            <b>AND:</b> The AND operator requires the terms on either side of it to both exist, but it searches for them independently.
        </li>
        <li>
            <b>OR:</b> The OR operator requires at least one of the two search terms on either side to match.
        </li>
        <li>
            <b>NOT:</b> The NOT operator excludes any task matching the search term after it.
        </li>
    </ul>
    <p>Note order of operations matters, the use of parenthesis is important when using multiple Boolean operators, for example: match all tasks that included the word "Final" and either the word "Test" or the word "QProcess", you can use parentheses to guide the search behavior.</p>
    <ul>
        <li>Some more helpful hints on using Boolean operators
            <ul>
                <li>These search terms are <i>not</i> case sensitive</li>
                <li>Multi-word terms <i>must</i> be in double quotes, regardless of anything else in thr search. "Q Family Office"</li>
                <li>Semicolons - <b>;</b> - cannot appear anywhere in the search criteria</li>
                <li>You <i>can</i> search for the words "and", "or", and "not", and for tasks containing parentheses; simply make sure they're in double-quotes. <b>"Complete and Final Test (not intermediate)"</b> will match any task with exactly that sequence of characters somewhere in its title, checklist or comments. </li>
            </ul>
        </li>
    </ul>
    <p>
        You can include archived results by checking the box "include archived." As you begin typing, results will be returned based on what you have typed so far. This will return both task names, and items matching within the checklist. You can also click on one of the suggested words and it will populate and search for you. Then the matched words will appear highlighted in red.
    </p>
    <img id="Picture 258" src="/Images/Help/image258.png" />
    <p style="color:red">Please note: Search is refreshed hourly, so new tasks may not appear in search results for up to an hour after task creation.</p>
    <br />
    <br />


    <!-- ============================================================
			    16. Task History
    ============================================================ -->
    <h2><a id="16"></a>16. Task History</h2>
    <p>
        Click this button to view all comments, change requests, and due date changes on a task. 
        The button is found when clicking on a task through My Tasks, Calendar, Manage Tasks, or Global Search. 
    </p>
    <img id="TH-1" src="/Images/Help/th-1.png" />
    <img id="TH-2" src="/Images/Help/th-2.png" />
    <img id="TH-3" src="/Images/Help/th-3.png" />
    <img id="TH-4" src="/Images/Help/th-4.png" />

    <br />
    <br />
    <!-- ============================================================
				17. Notifications
	 ============================================================ -->
    <h2><a id="17"></a>17. Notifications</h2>
    <p>Notifications on new task assignments or responses to your comment will be displayed here. The bell icon at the top right will have a red badge with a number on it to indicate the number of new notifications you have.</p>
    <p>When clicking the bell, the red badge will disappear to indicate that you have <b>seen</b> them</p>
    <img id="Notif-1" src="/Images/Help/Notif-1.png" />
    <p>Notifications will remain bolded until you click on each notification and <b>read</b> them</p>
    <img id="Notif-2" src="/Images/Help/Notif-2.png" />
    <p>You can delete notifications by clicking "delete" on it. Notifications you've <b>read</b> will delete after 7 days. Notifications you've <b>never seen</b> will delete after 30 days</p>
    <p>You can go to manage tasks by clicking "manage" on the notification</p>
    <img id="Notif-3" src="/Images/Help/Notif-3.png" />

     <!-- ============================================================
				18. Automations
	 ============================================================ -->
    <h2><a id="18"></a>18. Automations</h2>
    <p>The automations page holds <i>linked deadlines</i> and <i>bulk uploads</i>.</p>
    <img id="Auto-1" src="/Images/Help/Auto-1.png" />
    <h3><a id="18.1"></a>18.1 Linked Deadlines</h3>
    <p>Linked deadlines will automatically associate the deadlines of two tasks. When the source task's deadline changes, the linked task's deadline will be offset based on the days specified. When the source task is completed, the deadline of the target task will be updated based on the completion date of the source task.</p>
    <img id="Auto-2" src="/Images/Help/Auto-2.png" />
    <h3><a id="18.2"></a>18.2 Bulk Task Upload</h3>
    <p>Bulk task upload allows one to upload hundreds of tasks through an Excel sheet at once.</p>
    <img id="Auto-3" src="/Images/Help/Auto-3.png" />
    <p>Fields that are left blank will automatically apply your preset preferences. Those can be changed by going to the "preferences" page next to the "automations" page at the bottom of the screen.</p>
    <img id="Auto-4" src="/Images/Help/Auto-4.png" />
    <br />
    <img id="Auto-5" src="/Images/Help/Auto-5.png" />

    <!-- ============================================================
				19. FAQ
	 ============================================================ -->
    <h2><a id="99"></a>19. Frequently Asked Questions</h2>
    <ul>
        <li><b>How can I schedule a task that occurs twice a month?</b>
            <ul>
                <li>Create two &quot;monthly&quot; assignments. Use the start date to specify which day of the month each should be scheduled on. *Note - the simplest way to do this is by creating one monthly assignment, then copying it and changing the start date.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>How does my supervisor get notified of overdue items?</b>
            <ul>
                <li>Checklist controllers get notified as soon as a task goes overdue. Additionally, controllers will get a daily email showing everything that is overdue.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>How do I see who filled out my checklist last week?</b>
            <ul>
                <li>Use the ‘History' report on the Reports tab to see checklists that have been completed in the past.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>I set my checklist to skip holidays and weekends but it is showing up on the calendar on a Saturday.</b>
            <ul>
                <li>The calendar shows only your due dates, which do not apply here. The holiday/weekend logic applies to the <i>due </i>date of a task.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>How do I change a due date?</b>
            <ul>
                <li>In your status report, it is very simple. Just click on the date, alter it, and click save. For checklists, you need to be a controller of the checklist in order to do this. Go to the 'Tasks I Control' tab and find the checklist you want to change. Open the checklist, and the appropriate assignment and find the scheduling area. *Please note that for recurring checklists, this change will not take affect until the next scheduling period. For one time checklists, the changes occur immediately.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>I accidentally completed an item, how do I get it back?</b>
            <ul>
                <li>If you are in the checklist portion of the application, go to the 'My Tasks' tab, find the checklist and click 'Open'. In your status report, you can do the same thing by clicking the green arrow on the left of the task.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>I created a task as a &quot;Simple Task&quot;, but would now like to add it to my status report. How do I change that?</b>
            <ul>
                <li>You can easily add tasks to your status report on the task summary page. Once the task is active, simply drag it to the appropriate section on your status report and it will show up.</li>
            </ul>
        </li>
    </ul>
    <ul>
        <li><b>I keep getting a pop-up asking me to install software every time I go to QProcess. How do I make it stop?</b>
            <ul>
                <li>If the pop-up is for MeadCo's ScriptX, just click Install. It should go away after that.
						<br />
                    <img id="Picture 163" src="/Images/Help/image127.gif" />
                </li>
            </ul>
        </li>
    </ul>

    <div class="back-to-top-container">
        <a href="#top" class="back-to-top"><i class="fa fa-arrow-up"></i>Top</a>
    </div>
</div>
<!-- Copyright � 2024 Renegade Swish, LLC -->

