class RedmineChartQuery < IssueQuery

  def initialize(attributes=nil, *args)
    super attributes
    self.filters.delete('status_id')
  end

end
