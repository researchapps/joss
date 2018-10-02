class HomeController < ApplicationController
  before_action :require_user, :only => %w(profile update_profile)
  before_action :require_editor, :only => %w(dashboard reviews incoming stats all)
  layout "dashboard", :only =>  %w(dashboard reviews incoming stats all)

  def index
    @papers = Paper.visible.limit(10)
  end

  def about
  end

  def dashboard
    if params[:editor]
      @editor = Editor.find_by_login(params[:editor])
    else
      @editor = Editor.first
    end

    @reviewer = params[:reviewer].nil? ? "@arfon" : params[:reviewer]
    @reviewer_papers = Paper.unscoped.where(":reviewer = ANY(reviewers)", reviewer: @reviewer).group_by_month(:accepted_at).count

    @accepted_papers = Paper.unscoped.visible.group_by_month(:accepted_at).count
    @editor_papers = Paper.unscoped.where(:editor => @editor).visible.group_by_month(:accepted_at).count
  end

  def incoming
    @active_tab = "incoming"
    @papers = Paper.in_progress.where(:editor => nil).paginate(
                :page => params[:page],
                :per_page => 10
              )
    render template: "home/reviews"
  end

  def reviews
    if params[:editor]
      @active_tab =
      @editor = Editor.find_by_login(params[:editor])
      @papers = Paper.in_progress.where(:editor => @editor).paginate(
                  :page => params[:page],
                  :per_page => 10
                )
    else
      @papers = Paper.everything.paginate(
                  :page => params[:page],
                  :per_page => 10
                )
    end
  end

  def all
    @papers = Paper.everything.paginate(
                :page => params[:page],
                :per_page => 10
              )
    render template: "home/reviews"
  end

  def update_profile
    check_github_username

    if current_user.update_attributes(user_params)
      redirect_back(:notice => "Profile updated", :fallback_location => root_path)
    end
  end

  def profile
    @user = current_user
  end

private

  def check_github_username
    if user_params.has_key?('github_username')
      if !user_params['github_username'].strip.start_with?('@')
        old = user_params['github_username']
        user_params['github_username'] = old.prepend('@')
      end
    end
  end

  def user_params
    params.require(:user).permit(:email, :github_username)
  end
end
