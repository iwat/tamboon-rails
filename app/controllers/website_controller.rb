class WebsiteController < ApplicationController
  before_filter :validate_token, only: %i(donate)
  before_filter :validate_amount, only: %i(donate)

  def index
    @token = nil
  end

  def donate
    charity = Charity.find_by(id: params[:charity])

    unless charity
      @token = retrieve_token(params[:omise_token])
      flash.now.alert = "[no_charity] #{t('.failure')}"
      render :index
      return
    end

    charge = Omise::Charge.create({
      amount: params[:amount].to_i * 100,
      currency: "THB",
      card: params[:omise_token],
      description: "Donation to #{charity.name} [#{charity.id}]",
    })

    if charge.paid
      charity.credit_amount(charge.amount)
    end

    unless charge.paid
      @token = nil
      flash.now.alert = "[pay_error] #{t('.failure')}"
      render :index
      return
    end

    flash.notice = t(".success")
    redirect_to root_path
  end

  private

  def retrieve_token(token)
    Omise::Token.retrieve(token)
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
