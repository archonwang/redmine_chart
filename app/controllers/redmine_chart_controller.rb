class RedmineChartController < ApplicationController
  unloadable
  menu_item :redmine_chart
  brfore_filter :find_project, :authorize
  before_filter :find_redmine_chart, :except => [:index, :new, :create, :preview]
  # :
  def index
    #@redmin_chart =Redmine_chart.find(:all, :conditions => ["project_id = #{@project.id} "])
	@name ='name get!!'
  end

  def new
  end

  def show
  end

  def edit
  end
  
  def preview
    @text = params[:redmine_chart][:description]
    render :partial => 'common/preview'
  end
private
  def find_project
  #project = param[:project_id] 
      @project = Project.find(params[:project_id])
      @redmine_chart =Redmine_chart.find(:all)
  rescue ActiveRecoed::RecordNotFound
      render_404
  end
  def find_redmine_chart
     @redmine_chart = Redmine_chart.find_by_id(params[:id]);
     render_404 unless @redmine_chart
  end
end
