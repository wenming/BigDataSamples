@echo off

@rem 
@rem The Mahout command script
@rem
@rem Environment Variables
@rem
@rem   MAHOUT_JAVA_HOME   The java implementation to use.  Overrides JAVA_HOME.
@rem
@rem   MAHOUT_HEAPSIZE    The maximum amount of heap to use, in MB. 
@rem                      Default is 1000.
@rem
@rem   HADOOP_CONF_DIR  The location of a hadoop config directory 
@rem
@rem   MAHOUT_OPTS        Extra Java runtime options.
@rem
@rem   MAHOUT_CONF_DIR    The location of the program short-name to class name
@rem                      mappings and the default properties files
@rem                      defaults to "$MAHOUT_HOME/src/conf"
@rem
@rem   MAHOUT_LOCAL       set to anything other than an empty string to force
@rem                      mahout to run locally even if
@rem                      HADOOP_CONF_DIR and HADOOP_HOME are set
@rem
@rem   MAHOUT_CORE        set to anything other than an empty string to force
@rem                      mahout to run in developer 'core' mode, just as if the
@rem                      -core option was presented on the command-line
@rem Commane-line Options
@rem
@rem   -core              -core is used to switch into 'developer mode' when
@rem                      running mahout locally. If specified, the classes
@rem                      from the 'target/classes' directories in each project
@rem                      are used. Otherwise classes will be retrived from
@rem                      jars in the binary releas collection or *-job.jar files
@rem                      found in build directories. When running on hadoop
@rem                      the job files will always be used.

@rem
@rem /*
@rem * Licensed to the Apache Software Foundation (ASF) under one or more
@rem * contributor license agreements.  See the NOTICE file distributed with
@rem * this work for additional information regarding copyright ownership.
@rem * The ASF licenses this file to You under the Apache License, Version 2.0
@rem * (the "License"); you may not use this file except in compliance with
@rem * the License.  You may obtain a copy of the License at
@rem *
@rem *     http://www.apache.org/licenses/LICENSE-2.0
@rem *
@rem * Unless required by applicable law or agreed to in writing, software
@rem * distributed under the License is distributed on an "AS IS" BASIS,
@rem * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem * See the License for the specific language governing permissions and
@rem * limitations under the License.
@rem */
setlocal enabledelayedexpansion

@rem disable "developer mode"
set IS_CORE=0
if [%1] == [-core] (
  set IS_CORE=1
  shift
)

if not [%MAHOUT_CORE%] == [] (
  set IS_CORE=1
)

set MAHOUT_HOME=%~dp0..\

if not [%MAHOUT_JAVA_HOME%] == [] (
  echo run java in %MAHOUT_JAVA_HOME%
  set JAVA_HOME=%MAHOUT_JAVA_HOME%
)

if [%JAVA_HOME%] == [] (
    echo JAVA_HOME is not set.
    exit /B 1
)

set JAVA=%JAVA_HOME%\bin\java\
set JAVA_HEAP_MAX=-Xmx1000m 

@rem check envvars which might override default args
if not [%MAHOUT_HEAPSIZE%] == [] (
  echo run with heapsize %MAHOUT_HEAPSIZE%
  set JAVA_HEAP_MAX=-Xmx%MAHOUT_HEAPSIZE%m
)

if [%MAHOUT_CONF_DIR%] == [] (
  set MAHOUT_CONF_DIR=%MAHOUT_HOME%\conf\
)

:main
@rem MAHOUT_CLASSPATH initially contains $MAHOUT_CONF_DIR, or defaults to $MAHOUT_HOME/src/conf
set MAHOUT_CLASSPATH="%MAHOUT_CONF_DIR%";"%MAHOUT_CONF_DIR%\*"
set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%$HADOOP_CONF_DIR%";"%$HADOOP_CONF_DIR%\*"
set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%JAVA_HOME%\lib\tools.jar"

if  %IS_CORE% == 0 (
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%*";"%MAHOUT_HOME%"
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%lib\*";"%MAHOUT_HOME%lib\"
) else (
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%\math\target\classes"
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%\core\target\classes"
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%\utils\target\classes"
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%\examples\target\classes"
  set MAHOUT_CLASSPATH=!MAHOUT_CLASSPATH!;"%MAHOUT_HOME%\core\src\main\resources"
)

@rem add development dependencies to MAHOUT_CLASSPATH
@rem for %%f in (dir /b "%MAHOUT_HOME%\examples\target\dependency\*.jar") do (
@rem     set MAHOUT_CLASSPATH=%MAHOUT_CLASSPATH%;"%%f"
@rem )

@rem default log directory & file
if [%MAHOUT_LOG_DIR%] == [] (
  set MAHOUT_LOG_DIR=%MAHOUT_HOME%\logs
)
if [%MAHOUT_LOGFILE%] == [] (
  set MAHOUT_LOGFILE=mahout.log
)

set MAHOUT_OPTS=%MAHOUT_OPTS% "-Dhadoop.log.dir=%MAHOUT_LOG_DIR%"
set MAHOUT_OPTS=%MAHOUT_OPTS% "-Dhadoop.log.file=%MAHOUT_LOGFILE%"

if not [%JAVA_LIBRARY_PATH%] == [] (
  set MAHOUT_OPTS=%MAHOUT_OPTS% "-Djava.library.path=%JAVA_LIBRARY_PATH%"
)

set CLASS=org.apache.mahout.driver.MahoutDriver

if [%MAHOUT_JOB%] == [] (
  for /F %%f in ('dir /b "%MAHOUT_HOME%\mahout-examples-*-job.jar"') do (
    set MAHOUT_JOB=%MAHOUT_HOME%\%%f
  )
)
@rem run it
if not [%MAHOUT_LOCAL%] == [] (
    echo "MAHOUT_LOCAL is set, running locally"
    %JAVA% %JAVA_HEAP_MAX% %MAHOUT_OPTS% -classpath %MAHOUT_CLASSPATH% %CLASS% %*
) else (
    if [%MAHOUT_JOB%] == [] (
        echo "ERROR: Could not find mahout-examples-*.job in %MAHOUT_HOME% or %MAHOUT_HOME%\examples\target"
        goto :eof
    ) else (
        set HADOOP_CLASSPATH=%MAHOUT_CLASSPATH%
        if /I [%1] == [hadoop] (
            echo Running: %HADOOP_HOME%\bin\%*
            call %HADOOP_HOME%\bin\%*
        ) else (
            echo Running: %HADOOP_HOME%\bin\hadoop jar %MAHOUT_JOB% %CLASS% %*
            call %HADOOP_HOME%\bin\hadoop jar %MAHOUT_JOB% %CLASS% %*
        )
    )
)  