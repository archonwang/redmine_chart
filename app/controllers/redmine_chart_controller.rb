class RedmineChartController < ApplicationController
  unloadable
  menu_item :redmine_chart
  brfore_filter :find_project, :authorize
  # :
  def index
    @redmin_chart =Redmine_chart.find(:all, :conditions => ["project_id = #{@project.id} "])
  end

  def new
  end

  def show
  end

  def edit
  end
private
  def find_project
  #project = param[:project_id] 
      @project = Project.find(params[:project_id])
      @redmine_chart =Redmine_chart.find(:all)
  rescue ActiveRecoed::RecordNotFound
      render_404
  end
end
