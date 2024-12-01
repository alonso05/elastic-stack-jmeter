#!/bin/bash

JMETER_HOME="/opt/homebrew/opt/jmeter/libexec"
java -cp "$JMETER_HOME/lib/ext/jmeter-plugins-manager.jar:$JMETER_HOME/lib/cmdrunner-2.0.jar" org.jmeterplugins.repository.PluginManagerCMDInstaller install jpgc-graphs-basic,jpgc-graphs-additional,jpgc-cmd
