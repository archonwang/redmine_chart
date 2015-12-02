Redmine::Plugin.register :redmine_chart do
  name 'Redmine Chart plugin'
  author 'ryuthky'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/ryuthky/redmine_burn_charts'
  author_url 'https://github.com/ryuthky/redmine_burn_charts/wiki'
  
  project_module :redmine_chart do
    permission :view_chart,  :redmine_chart =>[:index, :show]
    permission :manage_chart, :redmine_chart =>[:new, :edit, :create, :update, :destroy, :preview], :require => :member
  end
  
  permission :redmine_chart,{:redmine_chart => [:index]}, public =>true
  menu :project_menu, :redmine_chart, {:controller =>'redmine_chart', :action =>'index'}, :param => :project_id, :caption => 'charts', :first =>true,

end
