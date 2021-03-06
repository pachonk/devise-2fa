require 'test_helper'
require 'integration_tests_helper'

class PersistenceTest < ActionDispatch::IntegrationTest
  def setup
    @old_persistence = User.otp_trust_persistence
    User.otp_trust_persistence = 3.seconds
  end

  def teardown
    User.otp_trust_persistence = @old_persistence
    Capybara.reset_sessions!
  end

  test 'a user should be requested the otp challenge every log in' do
    # log in 1fa
    user = enable_otp_and_sign_in
    otp_challenge_for user

    visit user_token_path
    assert_equal user_token_path, current_path

    sign_out
    sign_user_in

    assert_equal user_credential_path, current_path
  end

  test 'a user should be able to set their browser as trusted' do
    # log in 1fa
    user = enable_otp_and_sign_in
    otp_challenge_for user

    visit user_token_path
    assert_equal user_token_path, current_path

    click_link('Trust this browser')
    assert_text 'Your browser is trusted.'
    sign_out

    sign_user_in

    assert_equal root_path, current_path
  end

  test 'trusted status should expire' do
    # log in 1fa
    user = enable_otp_and_sign_in
    otp_challenge_for user

    visit user_token_path
    assert_equal user_token_path, current_path

    click_link('Trust this browser')
    assert_text 'Your browser is trusted.'
    sign_out

    sleep User.otp_trust_persistence.to_i + 1
    sign_user_in

    assert_equal user_credential_path, current_path
  end
end
