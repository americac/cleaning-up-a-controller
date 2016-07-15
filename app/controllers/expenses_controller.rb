class ExpensesController < ApplicationController
  def index
    @user = User.find(user_id)
    @expenses = get_expenses
  end

  def new
    @user = User.find(user_id)
  end

  def create
    user = User.find(user_id)

    @expense = user.expenses.new(expense_params)

    if @expense.save
      send_email(user)

      redirect_to user_expenses_path(user)
    else
      render :new, status: :bad_request
    end
  end

  def update
    user = User.find(user_id)

    @expense = user.expenses.find(id)

    if !@expense.approved
      @expense.update_attributes!(expense_params)
      flash[:notice] = 'Your expense has been successfully updated'
      redirect_to user_expenses_path(user_id: user.id)
    else
      flash[:error] = 'You cannot update an approved expense'
      render :edit
    end
  end

  def approve
    @expense = Expense.find(expense_id)
    @expense.update_attributes!(approved: true)

    render :show
  end

  def destroy
    expense = Expense.find(id)
    user = User.find(user_id)
    expense.update_attributes!(deleted: true)

    redirect_to user_expenses_path(user_id: user.id)
  end

  private

  def send_email(user)
    email_body = "#{@expense.name} by #{user.full_name} needs to be approved"
    mailer = ExpenseMailer.new(address: 'admin@expensr.com', body: email_body)
    mailer.deliver
  end

  def get_expenses
    if approved.nil?
      expenses = Expense.where(user: @user, deleted: false)
    else
      expenses = Expense.where(user: @user, approved: approved, deleted: false)
    end

    if !min_amount.nil?
      expenses = expenses.where('amount > ?', min_amount)
    end

    if !max_amount.nil?
      expenses = expenses.where('amount < ?', max_amount)
    end
    expenses
  end

  def expense_id
    params[:expense_id]
  end

  def approved
    params[:approved]
  end

  def min_amount
    params[:min_amount]
  end

  def max_amount
    params[:max_amount]
  end

  def id
    params[:id]
  end

  def user_id
    params[:user_id]
  end

  def expense_params
    params.require(:expense).permit(:name, :amount, :approved)
  end
end
