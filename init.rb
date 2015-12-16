Redmine::Plugin.register :redmine_chart do
# プラグイン一覧表示画面
  name 'Redmine Chart plugin'
  author 'ryuthky'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/ryuthky/redmine_burn_charts'
  author_url 'https://github.com/ryuthky/redmine_burn_charts/wiki'
  # プラグイン設定表示
  settings :default =>{ 'show_account_menu' => 'true'}, :partial =>'settings/burn_charts_settings'
  
  # プラグインモジュール権限設定
  project_module :redmine_chart do
    permission :view_chart,  :redmine_chart =>[:index, :show]
    permission :manage_chart, 
    :redmine_chart =>[:new, :edit, :create, :update, :destroy, :preview], 
    :require => :member
  end
 
  permission :redmine_chart, { :redmine_chart => [:index] }, :public => true
  
  # アカウントメニュー追加  
  menu :project_menu, :redmine_chart , 
  {:controller =>'redmine_chart', :action =>'index'},
   :param => :project_id, 
   :caption => :label_redmine_chart, 
   :after => :gantt
   :if => Proc.new{User.current.logged? && Setting.plugin_redmine_chart['show_account_menu']}
  
  # プロジェクトメニュー追加  
  menu :account_menu, :redmine_chart , 
  {:controller =>'redmine_chart', :action =>'index'}, 
  :caption => :label_redmine_chart, 
  :after => :my_account

end
