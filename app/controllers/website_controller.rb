class WebsiteController < ApplicationController
  before_filter :validate_token, only: %i(donate)
  before_filter :validate_amount, only: %i(donate)
  before_filter :set_charity, only: %i(donate)

  def index
    @token = nil
  end

  def donate
    fund = OmiseFundService.create_fund({
      amount: (params[:amount].to_f * 100).to_i,
      currency: "THB",
      card: params[:omise_token],
      description: "Donation to #{@charity.name} [#{@charity.id}]",
    })

    @charity.with_lock do
      @charity.donate(fund)
    end

    flash.notice = t(".success")
    redirect_to root_path
  rescue => e
    @token = nil
    flash.now.alert = e.to_s
    render :index
  end

  private

  def retrieve_token(token)
    Omise::Token.retrieve(token)
  end

  def set_charity
    if params[:charity] == "random"
      @charity = Charity.random
    else
      @charity = Charity.find_by(id: params[:charity])
    end

    unless @charity
      @token = retrieve_token(params[:omise_token])
      flash.now.alert = "[no_charity] #{t('.failure')}"
      render :index
    end
  end

  def validate_token
    return if params[:omise_token].present?

    @token = nil
    flash.now.alert = "[no_token] #{t('.failure')}"
    render :index
  end

  def validate_amount
    return if params[:amount].present? && params[:amount].to_i > 20

    @token = retrieve_token(params[:omise_token])
    flash.now.alert = "[invalid_amount] #{t('.failure')}"
    render :index
  end
end
