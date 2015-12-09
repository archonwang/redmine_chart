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
    category = [1,3,5,7]
    current_quantity = [1000,5000,3000,8000]

    @graph = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: 'ItemXXXの在庫の推移')
      f.xAxis(categories: category)
      f.series(name: '在庫数', data: current_quantity)
    end
	
	@multiple = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text => "Population vs GDP For 5 Big Countries [2009]")
        f.xAxis(:categories => ["United States", "Japan", "China", "Germany", "France"])
        f.series(:name => "GDP in Billions", :yAxis => 0, :data => [14119, 5068, 4985, 3339, 2656], type: 'column')
        f.series(:name => "Population in Millions", :yAxis => 1, :data => [310, 127, 1340, 81, 65])
        f.yAxis [
          {:title => {:text => "GDP in Billions", :margin => 70} },
          {:title => {:text => "Population in Millions"}, :opposite => true},
        ]
        f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
        #f.chart({:defaultSeriesType=>"column"})
		f.option[:chart][:defaultSeriesType]= 'line'
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
