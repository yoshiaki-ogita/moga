class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      log_in(user)
      redirect_to home_path, notice: "ログインしました"
    else
      # どちらが違うかは教えない（他人のメールアドレスを探られないため）
      flash.now[:alert] = "メールアドレスかパスワードが正しくありません"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: "ログアウトしました", status: :see_other
  end
end
