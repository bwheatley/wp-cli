Feature: Manage WordPress installation

  @download
  Scenario: Empty dir
    Given an empty directory

    When I try `wp core is-installed`
    Then the return code should be 1
    And STDERR should not be empty

    When I run `wp core download --quiet`
    Then the wp-settings.php file should exist

  @download
  Scenario: Localized install
    Given an empty directory
    When I run `wp core download --locale=de_DE`
    Then the wp-settings.php file should exist

  Scenario: No wp-config.php
    Given an empty directory
    And WP files

    When I try `wp core is-installed`
    Then the return code should be 1
    And STDERR should not be empty

    When I try `wp core install`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: wp-config.php not found.
      Either create one manually or use `wp core config`.
      """
    
    Given a wp-config-extra.php file:
      """
      define( 'WP_DEBUG_LOG', true );
      """
    When I run `wp core config --extra-php < wp-config-extra.php`
    Then the wp-config.php file should contain:
      """
      define('AUTH_SALT',
      """
    And the wp-config.php file should contain:
      """
      define( 'WP_DEBUG_LOG', true );
      """

    When I try the previous command again
    Then the return code should be 1
    And STDERR should not be empty

  Scenario: Database doesn't exist
    Given an empty directory
    And WP files
    And wp-config.php

    When I try `wp core is-installed`
    Then the return code should be 1
    And STDERR should not be empty

    When I run `wp db create`
    Then STDOUT should not be empty

  Scenario: Database tables not installed
    Given an empty directory
    And WP files
    And wp-config.php
    And a database

    When I try `wp core is-installed`
    Then the return code should be 1
    And STDERR should be:
      """
      Error: The site you have requested is not installed.
      Run `wp core install`.
      """

    When I run `wp core install --url='localhost:8001' --title='Test' --admin_email=admin@example.com --admin_password=1`
    Then STDOUT should not be empty

    When I run `wp eval 'echo home_url();'`
    Then STDOUT should be:
      """
      http://localhost:8001
      """

  Scenario: Full install
    Given a WP install

    When I run `wp core is-installed`
    Then STDOUT should be empty

    When I run `wp eval 'var_export( is_admin() );'`
    Then STDOUT should be:
      """
      true
      """ 

    When I run `wp eval 'var_export( function_exists( 'media_handle_upload' ) );'`
    Then STDOUT should be:
      """
      true
      """

    # Can complain that it's already installed, but don't exit with an error code
    When I try `wp core install --url='localhost:8001' --title='Test' --admin_email=admin@example.com --admin_password=1`
    Then the return code should be 0

  Scenario: Convert install to multisite
    Given a WP install

    When I run `wp eval 'var_export( is_multisite() );'`
    Then STDOUT should be:
      """
      false
      """ 

    When I run `wp core install-network --title='test network'`
    Then STDOUT should not be empty

    When I run `wp eval 'var_export( is_multisite() );'`
    Then STDOUT should be:
      """
      true
      """ 

    When I try `wp core install-network --title='test network'`
    Then the return code should be 1

  Scenario: Install multisite from scratch
    Given an empty directory
    And WP files
    And wp-config.php
    And a database

    When I run `wp core multisite-install --url=foobar.org --title=Test --admin_email=admin@example.com --admin_password=1`
    Then STDOUT should not be empty

    When I run `wp eval 'echo $GLOBALS["current_site"]->domain;'`
    Then STDOUT should be:
      """
      foobar.org
      """ 

    # Can complain that it's already installed, but don't exit with an error code
    When I try `wp core multisite-install --url=foobar.org --title=Test --admin_email=admin@example.com --admin_password=1`
    Then the return code should be 0

  Scenario: Install multisite from scratch, with MULTISITE already set in wp-config.php
    Given a WP multisite install
    And I run `wp db reset --yes`

    When I run `wp core multisite-install --title=Test --admin_email=admin@example.com --admin_password=1`
    Then STDOUT should not be empty

    When I run `wp eval 'echo $GLOBALS["current_site"]->domain;'`
    Then STDOUT should be:
      """
      example.com
      """

  Scenario: Custom wp-content directory
    Given a WP install
    And a custom wp-content directory

    When I run `wp plugin status hello`
    Then STDOUT should not be empty
