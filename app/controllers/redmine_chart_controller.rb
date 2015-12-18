class RedmineChartController < ApplicationController
  unloadable
  menu_item :redmine_chart
  # :
  helper :issues
  include IssuesHelper
  
  
  #before_filter :find_project, :authorize
  before_filter :select_project, :require_login
  before_filter :find_redmine_chart, :except => [:index, :new, :create, :preview]

  def index
    # プロジェクトメニュー表示
    
    @today = Date.today
    @due_date = @project.due_date
    @start_date = @project.start_date
    
    # ログインユーザー取得
    @crnt_uname = User.current.login
    @crnt_uid = User.current.id

    # プロジェクトチケットリスト取得　@
    get_project_issues # @project_issuesを取得してくる

    # プロジェクト別ユーザの担当チケット数 project count
    @prj_list_cnt = []
    
    get_filter_issues(" assigned_to_id = ?",  @crnt_uid )
    @all_assigned_list = @filter_issues 
    @all_assigned = @all_assigned_list.count
    
    Project.all.each{ |prjobj|
     @assigned_prj=@all_assigned_list.joins("INNER JOIN projects prj on prj.id = issues.project_id ").where(project_id: prjobj.id )
     @prj_list_cnt[prjobj.id]=[Project.find(prjobj.id).name , @assigned_prj.where(project_id: prjobj.id ).count]
    }

    # プロジェクトの担当チケットステータス数　status_count
    
    get_answering_issues( "assigned_to_id = ?", @crnt_uid)
    @assigned_list = @answering_issuses
    @status_list_cnt = []              
    @assigned = @assigned_list.count
    @open = @assigned_list.open.count
    IssueStatus.all.each{ | stslist |
    @assigned_stats = @assigned_list.joins("INNER JOIN issue_statuses ist on ist.id = issues.status_id ").where(status_id: stslist.id )
     @status_list_cnt[stslist.id]= [IssueStatus.find(stslist.id).name , @assigned_stats.where(status_id: stslist.id ).count]
   }
     
    # 円グラフ
     # status_count
    @chart = LazyHighCharts::HighChart.new('pie') do |f|
    f.chart({defaultSeriesType: 'pie', margin: [50, 200, 60, 170]})
    f.series({
      type: 'pie',
      name: 'Issues',
      data:   @status_list_cnt
    })
    end
     # project count
    @chart2 = LazyHighCharts::HighChart.new('pie') do |f|
    f.chart2({defaultSeriesType: 'pie', margin: [50, 200, 60, 170]})
    f.series({
      type: 'pie',
      name: 'Issues',
      data:  @prj_list_cnt
    })
    end
    
    # 折れ線グラフ
    category = [1,3,5,7]
    current_quantity = [1000,5000,3000,8000]

    @graph = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: 'ItemXXXの在庫の推移')
      f.xAxis(categories: category)
      f.series(name: '在庫数', data: current_quantity)
    end
	
	# 折れ線と棒グラフMIX
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
	f.chart({:defaultSeriesType=> 'line'})
        # いずれイメージ出力するf.exporting(:enabled=>true,:filename=>"multi.png")
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
  # project id 取得
  def find_project
      @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
      render_404
  end
  # plugin のid 取得
  def find_redmine_chart
     @redmine_chart = RedmineChart.find_by_id(params[:id]);
     render_404 unless @redmine_chart
  end
  # 選択project 取得
  def select_project
     find_project
	 if @project.nil? then
	 @project = Project.first 
	 end
  end
  # 選択version 取得
  def select_version
	@versions =@project.versions.sort
  end
  #  該当プロジェクトチケットデータ取得
  def get_project_issues
        @project_issues =  Issue.where(["project_id = ? ", @project])
  end
  #  該当チケットデータ取得
  def get_filter_issues( key,  id )
        @filter_issues =  Issue.where([ key, id ])
  end
  # プロジェクト該当チケットデータ取得
  def get_answering_issues( key,  id )
	@answering_issuses = @project_issues.where([ key, id ])
  end
  # データ開始日
  def find_issues_start_date
  end
  # データ終了日
  def find_issues_end_date
  end
end
