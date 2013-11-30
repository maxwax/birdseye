BIRDSEYE TODO LIST
------------------

The following is a rough list of things on the to-do list for Birdseye
development

TESTING
-------

* Test on Large systems, both bare-metal and cloud
* Test on SLES 11 SP3 Xen Domain0 hypervisor host 

REQUIRED
--------

* A better alternate CSS style than my 'typewriter' attempt
* Improved CSS styling
* Simple Javascript based "Top" functionality

IMPROVEMENTS/FIXES
------------------

* SLES11SP3: Determine kernels installed (My rpm tricks are unavailable)
* SLES11SP3: App Armor reporting
* SLES11SP3: Reporting on zypper configuration

WISH LIST
-----------

* Packages (RPM,Deb)- Ease of Use, standardization on deployment expecations

* Comprehensive Documentation (How many people would read this?)

* Add plugin variables before/after each section to allow users to insert
  bits of bash code to conduct proprietary or specialized reporting

* Implement a user-friendly list of PCI cards and slots ('sutl cards')
* Implement a user-friendly list of storage devices ('sutl hbas')

* Report on more than one IP list for an individal network device

* Better IPV6 Reporting

* Debian: Show init script configuration instead of chkconfig/systemctl

* Build the Table of Contents in parallel to the handling and reporting
  of individual items.  This would allow us to grey-out entries in the TOC
  which are unable to be reported on.  Right now with its one-pass approach
  the TOC contains entries for things which lead the user to no useable data.

* More testing on UEFI systems 'uefivars -l' for example (need hw)

* Incorporate additional reporting from sosreport and other similar programs.

* Better reporting of power management (Warning: multiple PM systems)

* Better reporting on cgroups, CPU and IO schedulers

* Add --include tips for verbose, educational output?

