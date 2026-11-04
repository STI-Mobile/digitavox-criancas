.PHONY: bootstrap setup format format-check analyze lint test test-unit test-widget test-integration coverage check build-android build-android-dev build-ios-dev setup-ios ios-sign ios-prepare-signing ios-build ios-testflight test-ios-tooling

BUILD_NUMBER ?=
BUILD_NUMBER_ARGUMENT = $(if $(BUILD_NUMBER),--build-number=$(BUILD_NUMBER))
FLAVOR ?=
IPA ?=

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
	flutter build apk --debug --flavor dev

build-android-dev:
	flutter build appbundle --release --flavor dev $(BUILD_NUMBER_ARGUMENT)

build-ios-dev:
	flutter build ipa --release --flavor dev --export-method app-store $(BUILD_NUMBER_ARGUMENT)

setup-ios:
	bundle config set --local path vendor/bundle
	bundle install

ios-sign:
	bundle exec fastlane ios sign flavor:"$(FLAVOR)"

ios-prepare-signing:
	bundle exec fastlane ios prepare_signing flavor:"$(FLAVOR)"

ios-build:
	bundle exec fastlane ios build flavor:"$(FLAVOR)" build_number:"$(BUILD_NUMBER)"

ios-testflight:
	bundle exec fastlane ios testflight flavor:"$(FLAVOR)" ipa:"$(IPA)"

test-ios-tooling:
	ruby -e 'Dir["test/tool/*_test.rb"].sort.each { |path| require_relative path }'
