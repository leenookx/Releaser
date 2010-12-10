#!/bin/bash

APP_NAME=$1

git clone ../$APP_NAME $TMP_DIR

cd $TMP_DIR

VERSION=`cat VERSION`
RELEASE_FILE="release-"$VERSION".tar.gz"
TMP_DIR=tmp_dir

rm -rf $APP_NAME/$RELEASE_FILE
rm -rf $TMP_DIR

# Create the site version information pages.
echo "<div class='text'><p>This is v" > app/views/site/version.html.erb
echo $VERSION >> app/views/site/version.html.erb
echo " of the TagTheOne site.</p>" >> app/views/site/version.html.erb
echo "<p>" >> app/views/site/version.html.erb
echo "<pre>" >> app/views/site/version.html.erb
cat RELEASE >> app/views/site/version.html.erb
echo "</pre>" >> app/views/site/version.html.erb
echo "<p>" >> app/views/site/version.html.erb
echo "</div>" >> app/views/site/version.html.erb
cd ..

cd $TMP_DIR
mv config/environment.rb.live config/environment.rb
mv public/dispatch.fcgi.live public/dispatch.fcgi
mv script/worker.live script/worker
mv config/mail_fetcher.yml.live config/mail_fetcher.yml
cd ..

# Ensure that we mark all puts statements in the ruby code
# as comments. This is because the production systems
# tend to throw errors if they encounter these kind of
# debug statements.
cd $TMP_DIR
find . -name "*[.]rb" -exec sed -i 's/^puts/#puts/' {} \;
cd ..

# Now, remove all comments from the code - that's not needed on the
# production servers anyway and will save us a little bit of space.
cd $TMP_DIR
find . -name "*[.]rb" | xargs sed -i '/^#[^!].*$/ d'
find . -name "*.html.erb" | xargs sed -i '/^$/d;s/^[ \t]*//;s/[ \t]*$//'
cd ..

FILES=`cat ignore_files`
cd $TMP_DIR
for FILE in $FILES
do
  rm -rf ${FILE}
done
cd ..

tar -C $TMP_DIR -c -z -f ../$APP_NAME/$RELEASE_FILE .
