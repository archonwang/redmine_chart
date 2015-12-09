class RedmineChartController < ApplicationController
  unloadable
  menu_item :redmine_chart
  before_filter :find_project, :authorize
  before_filter :find_redmine_chart, :except => [:index, :new, :create, :preview]
  # :
  def index
    @name ='name get!!'
    @chart = LazyHighCharts::HighChart.new('pie') do |f|
    f.chart({defaultSeriesType: 'pie', margin: [50, 200, 60, 170]})
    f.series({
      type: 'pie',
      name: 'hoge',
      data: [
        ['hoge', 50.0],
        ['huga', 25.0],
        ['piyo', 25.0],
        ['hage', 0]
      ]
    })
   end
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
      @project = Project.find(params[:project_id])
      #@redmine_chart =redmine_chart.find(:all)
  rescue ActiveRecord::RecordNotFound
      render_404
  end
  def find_redmine_chart
     @redmine_chart = Redmine_chart.find_by_id(params[:id]);
     render_404 unless @redmine_chart
  end
end
