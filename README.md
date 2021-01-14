# Elevator simulator

An elevator simulator with a GUI in Java, and a controller in Prolog.
The communication is done by messages, UDP datagrams.

To build the UI of the 'elevator' project, use Apache Ant : `ant`.

To build the .so library do : `make`.

To run the Project, use the shells:
* [run.sh](run.sh) starts the Java UI first, then the Prolog controller, it's interactive
* [run-record-scenario.sh](run-record-scenario.sh), the same but records the user actions into a file to replay later
* [run-execute-scenario.sh](run-execute-scenario.sh), plays the scenario
* [run-execute-scenario-log-to-file.sh](run-execute-scenario-log-to-file.sh), plays the scenario and records states into a file which may be used to draw chronograms. Requires a configuration file, like [prolog-states.log.properties](prolog-states.log.properties)

To draw the chronograms, use Apache Ant target `ant display-chronograms`
