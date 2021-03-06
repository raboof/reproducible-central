#!/bin/bash

repo=https://repo.maven.apache.org/maven2
groupId=org.apache.maven.plugins
artifactId=maven-javadoc-plugin
groupDir=$(echo ${groupId} | tr '.' '/')

scm=https://github.com/apache/${artifactId}.git
build="mvn -Dmaven.test.skip package"

versionsWithoutTag=""
versions="2.0-beta-1 2.0-beta-2 2.0-beta-3 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.6.1 2.7 2.8 2.8.1 2.9 2.9.1 2.10 2.10.1 2.10.2 2.10.3 2.10.4
3.0.0-M1 3.0.0 3.0.1 3.1.0 3.1.1 3.2.0"

mkdir --parents target
pushd target > /dev/null
[ -d ${artifactId} ] || git clone ${scm}

mkdir --parents central
cd central
for version in ${versionsWithoutTag} ${versions}
do
  [ -f ${artifactId}-${version}.jar.sha1 ] || wget ${repo}/${groupDir}/${artifactId}/${version}/${artifactId}-${version}.jar.sha1
  [ -f ${artifactId}-${version}.jar ] || wget ${repo}/${groupDir}/${artifactId}/${version}/${artifactId}-${version}.jar
  [ -f ${artifactId}-${version}.pom ] || unzip -p ${artifactId}-${version}.jar META-INF/maven/${groupId}/${artifactId}/pom.xml > ${artifactId}-${version}.pom
done

for version in ${versionsWithoutTag} ${versions}
do
  pomDate=$(unzip -v ${artifactId}-${version}.jar META-INF/maven/${groupId}/${artifactId}/pom.xml | grep "META-INF/maven/${groupId}/${artifactId}/pom.xml" | sed 's/.*\(....-..-..\).*/\1/')
  outputTimestamp=$(unzip -p ${artifactId}-${version}.jar META-INF/maven/${groupId}/${artifactId}/pom.xml | grep "<project.build.outputTimestamp>" | sed 's/^.*<project.build.\(outputTimestamp>[^<]+\).*$/\1/')
  buildJdk=$(unzip -p ${artifactId}-${version}.jar META-INF/MANIFEST.MF | dos2unix | grep "Build-Jdk")
  unzip -p ${artifactId}-${version}.jar org/apache/maven/plugins/javadoc/JavadocJar.class > ../tmp.class 2> /dev/null
  unzip -p ${artifactId}-${version}.jar org/apache/maven/plugin/javadoc/JavadocJar.class >> ../tmp.class 2> /dev/null
  target=$(file -b ../tmp.class | cut -c 27-)
  #createdBy=$(unzip -p ${artifactId}-${version}.jar META-INF/MANIFEST.MF | dos2unix | grep "Created-By")

  win="" && $(grep -q $'\r' ${artifactId}-${version}.pom) && win=", built on Windows"

  echo -e "${pomDate}   ${version}\t${buildJdk}, bytecode ${target}${win} ${outputTimestamp}"
done

popd > /dev/null
