Redmine::Plugin.register :redmine_chart do
  name 'Redmine Chart plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  project_module :redmine_chart do
    permission :view_chart,  :redmine_chart =>[:index, :show]
    permission :mange_chart, :redmine_chart =>[:new, :edit, :create, :update, :destroy, :preview], :require => :member
  end
  
  menu :project_menu, :redmine_chart, {:controller =>'redmine_chart', :action =>`index`}, :param => :project_id, :caption => "chart"

end
