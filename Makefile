.PHONY: bootstrap setup format format-check analyze lint test test-unit test-widget test-integration coverage check build-android build-android-beta build-ios-beta

BUILD_NUMBER ?=
BUILD_NUMBER_ARGUMENT = $(if $(BUILD_NUMBER),--build-number=$(BUILD_NUMBER))

bootstrap:
	flutter pub get

setup: bootstrap

format:
	dart format lib test integration_test

format-check:
	dart format --output=none --set-exit-if-changed lib test integration_test

analyze:
	flutter analyze --fatal-infos --fatal-warnings

lint: analyze

test: test-unit test-widget

test-unit:
	flutter test test/unit

test-widget:
	flutter test test/widget

test-integration:
	flutter test integration_test

coverage:
	flutter test --coverage test

check: format-check analyze test

build-android:
	flutter build apk --debug

build-android-beta:
	flutter build appbundle --release --dart-define=APP_ENV=beta $(BUILD_NUMBER_ARGUMENT)

build-ios-beta:
	flutter build ipa --release --export-method app-store --dart-define=APP_ENV=beta $(BUILD_NUMBER_ARGUMENT)
