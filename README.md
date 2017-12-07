# check_lenovo_xcc_bash
script to check health, fans, voltage and temperature

This script is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This script is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Script for monitoring sensors (temperature, fans and voltage) and
health of LENOVO servers using SNMPv3 to the xclarity controller (XCC).

Version 0.0.2 2017-12-03
add the compare with dot, just remove the dot, compate the bigger number
remove SNMP v1, no longer supported by XCC
usage help more accurate
finish following checks: health, fans, voltage, temperature
Version 0.0.1 2017-11-23
based of the check_ibm_imm.sh from
Ulric Eriksson <ulric.eriksson@dgc.se>
modified by Silvio Erdenberger <serdenberger@lenovo.com>


has to be ask for flex vs. rack/tower
flex -> no fans maybe

Tested agains SR950 & SR630
