#!/bin/bash

APP_NAME=$1

TMP_DIR=tmp_dir

if [ -d "$APP_NAME/$TMP_DIR" ]
then
  rm -rf $APP_NAME/$TMP_DIR
fi

git clone ../$APP_NAME $APP_NAME/$TMP_DIR

cd $APP_NAME/$TMP_DIR

VERSION=`cat VERSION`
RELEASE_FILE="release-"$VERSION".tar.gz"

rm -rf $APP_NAME/$RELEASE_FILE

# Create the site version information pages.
echo "<div class='text'><p>This is v" > app/views/home/version.html.erb
echo $VERSION >> app/views/home/version.html.erb
echo "</p>" >> app/views/home/version.html.erb
echo "<p>" >> app/views/home/version.html.erb
echo "<pre>" >> app/views/home/version.html.erb
cat RELEASE >> app/views/home/version.html.erb
echo "</pre>" >> app/views/home/version.html.erb
echo "<p>" >> app/views/home/version.html.erb
echo "</div>" >> app/views/home/version.html.erb

# Ensure that we mark all puts statements in the ruby code
# as comments. This is because the production systems
# tend to throw errors if they encounter these kind of
# debug statements.
find . -name "*[.]rb" -exec sed -i 's/^puts/#puts/' {} \;

# Now, remove all comments from the code - that's not needed on the
# production servers anyway and will save us a little bit of space.
find . -name "*[.]rb" | xargs sed -i '/^#[^!].*$/ d'
find . -name "*.html.erb" | xargs sed -i '/^$/d;s/^[ \t]*//;s/[ \t]*$//'

FILES=`cat ignore_files`
for FILE in $FILES
do
  rm -rf ${FILE}
done

# Finally, apply any specific project configuration files.
cp -r ~/my_codaset/projectconfigs/${APP_NAME}/* .

mv app/controllers/application_controller.rb app/controllers/application.rb
secret=`date | md5sum | cut -d' ' -f1`
sed -i "s/abc123/$secret/" app/controllers/application.rb

cd ..

tar -C $TMP_DIR -c -z -f ../$APP_NAME/$RELEASE_FILE .

rm -rf $TMP_DIR

