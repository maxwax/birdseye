# birdseye

**Birdseye is a Bash shell script that generates a comprehensive system report including as many details about a Linux operating environment as possible.**

It focuses its reporting on the *environment* where programs can run: that means the Linux OS installation, hardware, storage, networking, and configuration aspects of the system.

It doesn't know about services and applications like web servers, databases, or your custom programs.  But it knows about the environment where they run.

> [!WARNING]
> I haven't done much maintenance on Birdseye since 2015 so while it still works, it is currently fairly out of date and may not work as expected.

## Recommended uses

* Generate a report about your new Linux system and explore its details via a user-friendly html page.  You'll also learn the Linux programs used to generate the output, too.

* Capture a report about your important systems each time you make a change and archive the reports elsewhere.  If your system needs rescuing later, having critical details available for reference can be very helpful recovery and repair actvities.

* Generate a report and attach it to bug reports for support and development teams to use.  This helps avoid the back-and-forth process of them asking questions about your environment later.

## Features

* Birdseye produces a single HTML file with embedded CSS formatting for easy review in a modern browser.

* Select output from some Linux diagnostic commands is included as ascii files for direct review.

* Birdeye requires only a single Bash script file that can be temporarily deployed on a Linux system.  **Birdseye doesn't modify your environment, deploy dependencies, or do anything else that might cause harm to your system.**

## Run as root

> [!WARNING]
> Birdseye runs many Linux programs to gather system details and many of these require root privelges so you have to run it as root or via sudo.

* Scary, I know!

* The source code is fully available for review so you can gain trust with it.

## Instructions

* Deploy the single `birdseye` bash script a Linux system.

* Run the script with sudo or as root.

  `sudo ./birdseye`

* Answer the questions

    Birdseye will ask you a few questions.  These questions are optional and you can press ENTER to use default values.

    This information is **only used to populate a header on the HTML report** and can be very useful in understanding the purpose of each report in a set of many.

    ```
    Answers to the following questions are used in Birdseye's HTML
    report to title and describe the system being inventoried.

    Providing a unique tag in the first question is highly recommended.

    All other questions are optional and can be skipped by hitting ENTER.


    (1/9) Provide a short tag to include with this [birdseye] ?
    ->hp-superdomex-dc-main-unit-db501

    (2/9) What's your name [Not specified] ?
    ->Happy User

    (3/9) What's your email address [Not specified] ?
    ->happyuser@example.com

    (4/9) What group/company/org are you in ('devops') [Not specified] ?
    ->Data center operations

    (5/9) A simple description for the issue being reported [Not specified] ?
    ->baseline for newly racked HP superdomex unit 501 in db group

    (6/9) Notes about the system hardware configuration? [Not specified]
    ->entry level config

    (7/9) Notes about the system software configuration? [Not specified]
    ->Baseline Linux OS, not yet configured for a workload

    (8/9) What is the FQDN for this systems primary NIC? [server501.db.example.com]
    ->server501.db.example.com

    (9/9) What is the FQDN for this systems out-of-band mgmt NIC? [null]
    ->server501-ilo.db.example.com
    ```

    Produces this report header:
    ```
    Birdseye System Inventory for server501.db.example.com

    Produced on Saturday, October 14 2023 at 21:10 by Happy User (happyuser@example.com) of Data center operations

    Purpose of this report: baseline for newly racked HP superdomex unit 501 in db group

    Hardware notes: entry level config

    Software notes: Baseline Linux OS, not yet configured for a workload

    Capture File birdseye.2023.1014.hp-superdomex-dc-main-unit-db501

    server501 is accessibile at server501.db.example.com with an out-of-band mgmt port at https://server501-ilo.db.example.com/
    ```
# Sample Report

* 2023 note: This is a very old, outdated report

A [Birdseye Sample](https://github.com/maxwax/birdseye/blob/master/birdseye-sample.html "Birdseye Sample") is available to see what Birdseye looks like.

