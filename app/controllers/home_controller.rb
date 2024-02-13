class HomeController < ApplicationController
  def index
    @main_categories = Category.take(12)
  end
end
