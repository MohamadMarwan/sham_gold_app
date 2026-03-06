@echo off
flutter config --enable-web
flutter pub get
flutter create --platforms=web .
echo DONE > done.txt
