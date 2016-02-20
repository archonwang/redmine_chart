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
   #初期値
   @query.date_to ||= Date.today

   get_project_dates
   @last_date  = params[:date_to]
   @first_date = params[:date_from]
   
    @today = Date.today
    @due_date = @project.due_date
    @start_date = @project.start_date     
    
    #　描画範囲決定

    @all_first_due_date=  @start_date.to_date
    unless @first_date.nil?
     if @start_date.to_date <= @first_date.to_date
        @all_first_due_date = @first_date.to_date 
     end
    end
    @all_last_due_date = @today
    unless @last_date.nil?
     if @last_date.to_date <= @today then
        @all_last_due_date = @last_date.to_date
     end
    end


   @issues = @query.issues(:include => [:assigned_to, :fixed_version])

   
   # プロジェクトメニュー表示
    
    # ログインユーザー取得
    @crnt_uname = User.current.login
    @crnt_uid = User.current.id

#   Account　Menuにて実装予定
#
#    # プロジェクトチケットリスト取得　@
#    get_project_issues # @project_issuesを取得してくる
#    # プロジェクト別ユーザの担当チケット数 project count
#    @prj_list_cnt = []
#    
#    get_filter_issues(" assigned_to_id = ?",  @crnt_uid )
#    @all_assigned_list = @filter_issues 
#    @all_assigned = @all_assigned_list.count
#    Project.all.each{ |prjobj|
#     @assigned_prj=@all_assigned_list.joins("INNER JOIN projects prj on prj.id = issues.project_id ").where(project_id: prjobj.id )
#     @prj_list_cnt << [Project.find(prjobj.id).name , @assigned_prj.where(project_id: prjobj.id ).count]
#    }

    # プロジェクトの担当チケットステータス数　status_count
    @status_list_cnt = []
    # チケット件数              
    @assigned = @issues.count 
logger.debug(">====================")
logger.debug( @assigned )
logger.debug("====================<")
    if @assigned == 0 then
      render_error :status => "該当データが無いか、権限がありません"
      return
    end
#    @open = @assigned_list.open.count
    IssueStatus.all.each{ | stslist |
    @status_list_cnt << [ IssueStatus.find(stslist.id).name ,@issues.select{| hash | hash[:status_id]== stslist.id }.count]
logger.debug(">====================")
logger.debug( @status_list_cnt )
logger.debug("====================<")   
   
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
 #    # project count
 #   @chart2 = LazyHighCharts::HighChart.new('pie') do |f|
 #   f.chart2({defaultSeriesType: 'pie', margin: [50, 200, 60, 170]})
 #   f.series({
 #     type: 'pie',
 #     name: 'Issues',
 #     data:  @prj_list_cnt
 #   })
 #   end

    
	# BurnUp Chart
 	    # 経過時間リストからプロジェクトとユーザーに合致するリストをチケット順にソート
        @date_by_count=[]           # 日別チケット件数
        @term_arry=[]               # 期間日付配列
        @term_by_count=[]           # 期間累積チケット件数
        @term_estimated_times = 0.0 # 期間累積予定工数
        @term_estimated_time =[]    # 期間予定工数
        @date_estimated_time=[]     # 日別予定工数
        @date_pending_time=[]       # 日別残工数
        @date_spent_times=[]        # 日別累積作業工数
        @date_plan_times=[]
        # 予定工数調整

            @term_date= (@all_last_due_date - @all_first_due_date).to_i
            @num = 0.0
        # 描画開始日から終了日までのチケット詳細
	#(@start_date.to_date..@today).each{ |index_date|
	(@all_first_due_date..@all_last_due_date).each{ |index_date|
           @num+=1
           # 開始日該当チケット抽出
           #@date_by_tickets = @assigned_list.where( start_date: index_date)
                      
           @date_by_tickets = @issues.select{|hash | hash[:start_date] >=index_date }
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
logger.debug(">====================term_estimated_times")
logger.debug(@term_estimated_times)
logger.debug("====================<")

           }
           @term_estimated_time << @term_estimated_times

           # 日別累積作業工数算出
           #@time_entries = TimeEntry.
           #              where(["user_id=:uid and spent_on <=:day1 and project_id=:pid ",
           #              {:uid => @crnt_uid, :day1 => index_date.to_time.to_date ,:pid => @project }]).all
           @time_entries = TimeEntry.where(['issue_id IN (?) AND spent_on = ?', @date_by_tickets,index_date])
            #  工数の入力がなければ0.0を代入
            if @time_entries.count == 0 then
               @date_estimated_time << 0.0
               @date_spent_times  << @date_estimated_time.sum
            else
                date_sum = 0
                @time_entries.each{ |entry|
                     date_sum += entry[:hours]
logger.debug(">====================entry[:hour]")
logger.debug(entry[:hours])
logger.debug("====================<")
                }
                @date_spent_times  << @date_estimated_time.sum + date_sum

                @date_estimated_time << date_sum
            end
logger.debug(">====================@date_spent_times ")
logger.debug(@date_spent_times)
logger.debug("====================<")
logger.debug(">====================@date_estimated_time ")
logger.debug(@date_estimated_time)
logger.debug("====================<")

            # 日別残工数
            
            @minas =@term_estimated_times.quo(@term_date).to_f
            @date_pending_time <<  @term_estimated_times - @date_estimated_time.last.to_f
            calc_est_time = @term_estimated_times - (@minas*@num).to_f
            if calc_est_time < 0 then
            	@date_plan_times << 0
            else
            	@date_plan_times << calc_est_time
            end
	}
	
    # BurnUp Chart
	@multiple2 = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text =>@crnt_uname+l(:label_redmine_chart_issues_story) )
        f.xAxis(:categories =>@term_arry )
        f.yAxis [
         {:title =>{:text=> l(:label_redmine_chart_issues_count), :margin => 1}},
         {:title =>{:text=> l(:label_redmine_chart_accumulated_time)}, :opposite => true },
        ]        
        f.series(:name => l(:label_redmine_chart_issues_per_date), :yAxis => 0, :data => @date_by_count,:type => 'column' )
        f.series(:name => l(:label_redmine_chart_issues_total), :yAxis => 0, :data => @term_by_count,:type => 'column' )
        f.series(:name => l(:label_redmine_chart_term_estimated_time), :yAxis => 1, :data => @term_estimated_time )#累積予定工数
        f.series(:name => l(:label_redmine_chart_actual_line), :yAxis => 1, :data => @date_spent_times )#累積作業工数
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
        f.series(:name => l(:label_redmine_chart_actual_line), :yAxis => 0, :data => @date_pending_time)
        f.series(:name => l(:label_redmine_chart_ideal_line), :yAxis => 0, :data => @date_plan_times )
        f.chart({:defaultSeriesType=> 'line'})
        f.plot_options({:column=>{:dataLabels =>{:enabled => true }}})
    end
  end

  def new
  end

  def show
#  retrieve_query
#  get_project_dates
    
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
  	return @query.date_from
  end
  # データ終了日
  def find_issues_end_date
  	return @query.date_to
  end
  def retrieve_charts_query
  if params[:set_filter] || session[:charts_query].nil? || session[:charts_query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = RedmineChartQuery.new(:name => "_",:filters => { 'assigned_to_id' => {:operator => '=', :values => ['me']}})
      @query.project = @project
      @query.build_from_params(params)
      session[:charts_query] = {:project_id => @query.project_id,
                                      :filters => @query.filters,
                                      :group_by => @query.group_by,
                                      :column_names => @query.column_names,
                                      :date_from => @query.date_from,
                                      :date_to => @query.date_to}
logger.debug(">====================")
logger.debug( "initial retrive" )
logger.debug( @query.date_from )
logger.debug("====================<")   
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
logger.debug(">====================")
logger.debug( "session retrive" )
logger.debug("====================<")   
    end
      sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
      sort_update(@query.sortable_columns)
      @query.sort_criteria = sort_criteria.to_a
  end
end
