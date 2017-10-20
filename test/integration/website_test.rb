require 'test_helper'

class WebsiteTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get "/"

    assert_response :success
  end

  test "that someone can't donate to no charity" do
    stub_token_retrieve do
      post donate_path, amount: "100", omise_token: "tokn_X", charity: ""
    end

    assert_template :index
    assert_equal "[no_charity] #{t('website.donate.failure')}", flash.now[:alert]
  end

  test "that someone can't donate 0 to a charity" do
    charity = charities(:children)

    stub_token_retrieve do
      post donate_path, amount: "0", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal "[invalid_amount] #{t('website.donate.failure')}", flash.now[:alert]
  end

  test "that someone can't donate less than 20 to a charity" do
    charity = charities(:children)

    stub_token_retrieve do
      post donate_path, amount: "19", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal "[invalid_amount] #{t('website.donate.failure')}", flash.now[:alert]
  end

  test "that someone can't donate without a token" do
    charity = charities(:children)
    post donate_path, amount: "100", charity: charity.id

    assert_template :index
    assert_equal "[no_token] #{t('website.donate.failure')}", flash.now[:alert]
  end

  test "that someone can donate to a charity" do
    charity = charities(:children)
    initial_total = charity.total
    expected_total = initial_total + 10025

    stub_success_charge(10025) do
      post_via_redirect donate_path, amount: "100.25", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal t("website.donate.success"), flash[:notice]
    assert_equal expected_total, charity.reload.total
  end

  test "that if the charge fail from omise side it shows an error" do
    charity = charities(:children)

    stub_failed_charge do
      post donate_path, amount: "999", omise_token: "tokn_X", charity: charity.id
    end

    assert_template :index
    assert_equal "[pay_error] #{t('website.donate.failure')}", flash.now[:alert]
  end

  test "that we can donate to a charity at random" do
    charities = Charity.all
    initial_total = charities.to_a.sum(&:total)
    expected_total = initial_total + 10075

    stub_token_retrieve do
      post donate_path, amount: "100.75", omise_token: "tokn_X", charity: "random"
    end

    assert_template :index
    assert_equal expected_total, charities.to_a.map(&:reload).sum(&:total)
    assert_equal t("website.donate.success"), flash[:notice]
  end

  private

  def stub_failed_charge
    fake_charge = OpenStruct.new({
      amount: 99900,
      paid:   false,
    })
    Omise::Charge.stub(:create, fake_charge) do
      yield
    end
  end

  def stub_success_charge(amount)
    fake_charge = OpenStruct.new({
      amount: amount,
      paid:   true,
    })
    Omise::Charge.stub(:create, fake_charge) do
      yield
    end
  end

  def stub_token_retrieve
    fake_token = OpenStruct.new({
      id: "tokn_X",
      card: OpenStruct.new({
        name: "J DOE",
        last_digits: "4242",
        expiration_month: 10,
        expiration_year: 2020,
        security_code_check: false,
      }),
    })
    Omise::Token.stub(:retrieve, fake_token) do
      yield
    end
  end
end
