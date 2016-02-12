class RedmineChartController < ApplicationController
  unloadable
  menu_item :redmine_chart
  # :
  helper :issues
  helper :queries
  include IssuesHelper
  include QueriesHelper
  helper :sort
  include SortHelper
 
  
  #before_filter :find_project, :authorize
  before_filter :select_project, :require_login
  before_filter :find_redmine_chart, :except => [:index, :new, :create, :preview, :show, ]

  def index

   #retrieve_query
   retrieve_charts_query

   get_project_dates
   @issues = @query.issues(:include => [:assigned_to, :fixed_version])

   
   # プロジェクトメニュー表示
   @last_date  = params[:date_to]
   @first_date = params[:date_from]
   @view_id = params[:assigned_to_id]
   
   
    @today = Date.today
    @due_date = @project.due_date
    @start_date = @project.start_date

    #　描画範囲決定
    @from_date =  @start_date.to_date
    unless @first_date.nil?
     if @start_date.to_date <= @first_date.to_date
        @from_date = @first_date.to_date 
     end
    end
    @to_date = @today
    unless @last_date.nil?
     if @last_date.to_date <= @today then
        @to_date = @last_date.to_date
     end
    end
     
    
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
     @prj_list_cnt << [Project.find(prjobj.id).name , @assigned_prj.where(project_id: prjobj.id ).count]
    }

    # プロジェクトの担当チケットステータス数　status_count
    
    get_answering_issues( "assigned_to_id = ?", @crnt_uid)
    @assigned_list = @answering_issuses
    @status_list_cnt = []              
    @assigned = @assigned_list.count
    @open = @assigned_list.open.count
    IssueStatus.all.each{ | stslist |
    @assigned_stats = @assigned_list.joins("INNER JOIN issue_statuses ist on ist.id = issues.status_id ").where(status_id: stslist.id )
     @status_list_cnt << [IssueStatus.find(stslist.id).name , @assigned_stats.where(status_id: stslist.id ).count]
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
	# BurnUp Chart
 	    # 経過時間リストからプロジェクトとユーザーに合致するリストをチケット順にソート
        @date_by_count=[]           # 日別チケット件数
        @term_arry=[]               # 期間日付配列
        @term_by_count=[]           # 期間累積チケット件数
        @term_estimated_times = 0.0 # 期間累積予定工数
        @term_estimated_time =[]    # 期間予定工数
        @date_estimated_time=[]     # 日別予定工数
        @date_spent_time=[]         # 日別残工数
        @date_plan_times=[]
        # 予定工数調整
            @all_last_due_date = @assigned_list.order("due_date DESC").first[:due_date]
            @all_first_due_date =@assigned_list.order("start_date ").first[:start_date]
            @term_date= (@all_last_due_date - @all_first_due_date).to_i
            @num = 0.0
        # 描画開始日から終了日までのチケット詳細
	#(@start_date.to_date..@today).each{ |index_date|
	(@all_first_due_date..@all_last_due_date).each{ |index_date|
           @num+=1
           # 開始日該当チケット抽出
           @date_by_tickets = @assigned_list.where( start_date: index_date)
           # 日別チケット件数 
           @date_by_count <<  @date_by_tickets.count
           # 表示期間の日付
           @term_arry << index_date
           # 累積チケット件数
           @term_by_count << @date_by_count.sum
           # 累積予定工数
           @date_by_tickets.each { |dat|
               if dat['estimated_hours']!= nil then  
                @term_estimated_times += dat['estimated_hours']
               end
           }
           @term_estimated_time << @term_estimated_times
           # 日別累積作業工数算出
           @time_entries = TimeEntry.
                         where(["user_id=:uid and spent_on <=:day1 and project_id=:pid ",
                         {:uid => @crnt_uid, :day1 => index_date.to_time.to_date ,:pid => @project }]).all
            #  工数の入力がなければ0.0を代入
            if @time_entries.count == 0 then
               @date_estimated_time << 0.0
            else
                date_sum = 0
                @time_entries.each{ |entry|
                     date_sum += entry[:hours]
                }
                @date_estimated_time << date_sum
            end

            # 日別残工数
            
            @minas =@term_estimated_times.quo(@term_date).to_f
            @date_spent_time <<  @term_estimated_times - @date_estimated_time.last.to_f
            calc_est_time = @term_estimated_times - (@minas*@num).to_f
            if calc_est_time < 0 then
            	@date_plan_times << 0
            else
            	@date_plan_times << calc_est_time
            end
	}
	
	@multiple2 = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text =>@crnt_uname+l(:label_redmine_chart_issues_story) )
        f.xAxis(:categories =>@term_arry )
        f.yAxis [
         {:title =>{:text=> l(:label_redmine_chart_issues_count), :margin => 1}},
         {:title =>{:text=> l(:label_redmine_chart_accumulated_time)}, :opposite => true },
        ]        
        f.series(:name => l(:label_redmine_chart_issues_per_date), :yAxis => 0, :data => @date_by_count,:type => 'column' )
        f.series(:name => l(:label_redmine_chart_issues_total), :yAxis => 0, :data => @term_by_count,:type => 'column' )
        f.series(:name => l(:label_redmine_chart_term_estimated_time), :yAxis => 1, :data => @term_estimated_time )
        f.series(:name => l(:label_redmine_chart_actual_line), :yAxis => 1, :data => @date_estimated_time )
        #f.series(:name => "累積残工数", :yAxis => 1, :data => @date_spent_time )
        #f.options[:chart][:defaultSeriesType] = "column"
        f.chart({:defaultSeriesType=> 'line'})
        f.plot_options({:column=>{:dataLabels =>{:enabled => true }}})
    end
    # BurnDown Chart
	@multiple3 = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text =>@crnt_uname+l(:label_redmine_chart_burn_down)+l(:label_redmine_chart) )
        f.xAxis(:categories =>@term_arry )
        f.yAxis [
         {:title =>{:text=> l(:label_redmine_chart_remaining_time)}, :opposite => true }, 
        ]        
        f.series(:name => l(:label_redmine_chart_actual_line), :yAxis => 0, :data => @date_spent_time)
        f.series(:name => l(:label_redmine_chart_ideal_line), :yAxis => 0, :data => @date_plan_times )
        f.chart({:defaultSeriesType=> 'line'})
        f.plot_options({:column=>{:dataLabels =>{:enabled => true }}})
    end
  end

  def new
  end

  def show
  retrieve_query
  get_project_dates
    
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
  #  該当プロジェクト日付データ取得
  def get_project_dates
    @project_due_date = @project.due_date
    @project_start_date = @project.start_date   
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
  def retrieve_charts_query
	      #@query = RedmineChartQuery.new(:name => "_")
	      #@query.project = @project
          #sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
          #sort_update(@query.sortable_columns)
          #@query.sort_criteria = sort_criteria.to_a
    if params[:set_filter] || session[:charts_query].nil? || session[:charts_query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = RedmineChartQuery.new(:name => "_")
      @query.project = @project
      @query.build_from_params(params)
      session[:charts_query] = {:project_id => @query.project_id,
                                      :filters => @query.filters,
                                      :group_by => @query.group_by,
                                      :column_names => @query.column_names,
                                      :date_from => @query.date_from,
                                      :date_to => @query.date_to}
    else
      # retrieve from session
      @query = RedmineChartQuery.new(:name => "_",
        :filters => session[:charts_query][:filters],
        :group_by => session[:charts_query][:group_by],
        :column_names => session[:charts_query][:column_names],
        :date_from => session[:charts_query][:date_from],
        :date_to => session[:charts_query][:date_to]
        )
      @query.project = @project
    end
      sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
      sort_update(@query.sortable_columns)
      @query.sort_criteria = sort_criteria.to_a
  end
end
