class InputSourcesController < ApplicationController
  before_filter :load_input_source, :except => [:new, :create, :find]
  before_filter :load_republished_feed, :only => [:new, :create]

  access_control do
    allow all, :to => [:show, :find]
    allow :owner, :of => :republished_feed, :to => [:new, :create, :edit, :update]
    allow :owner, :of => :input_source, :to => [:edit, :update, :destroy]
    allow :superadmin, :input_source_admin
  end

  def new
    @input_source = InputSource.new(:effect => params[:effect])
    #ok because we're using ACL9 to protect this method.
    @input_source.republished_feed_id = params[:republished_feed_id]
  end

  def create
    @input_source = InputSource.new()
    @input_source.attributes = params[:input_source]

    #ok because we're using ACL9 to protect this method.
    @input_source.republished_feed_id = params[:input_source][:republished_feed_id]

    respond_to do|format|
      if @input_source.save
        current_user.has_role!(:owner, @input_source)
        current_user.has_role!(:creator, @input_source)
        flash[:notice] = 'Add that input source'
        format.html{redirect_to republished_feed_url(@republished_feed)}
      else
        flash[:error] = 'Could not add that input source'
        format.html {render :action => :new}
      end
    end
  end

  def update
    @input_source.attributes = params[:input_source]
    respond_to do|format|
      if @input_source.save
        current_user.has_role!(:editor, @input_source)
        flash[:notice] = 'Updated that input source'
        format.html{redirect_to republished_feed_url(@input_source.republished_feed)}
      else
        flash[:error] = 'Could not update that input source'
        format.html {render :action => :edit}
      end
    end
  end

  def find
    #Here's where we'll return a json object of possible feed sources.

    @search = Sunspot.new_search Feed, FeedItem, FeedItemTag

    @search.build do
      text_fields do
        any_of do
          with(:description).starting_with(params[:q])
          with(:content).starting_with(params[:q])
          with(:title).starting_with(params[:q])
          with(:tag).starting_with(params[:q])
          with(:authors).starting_with(params[:q])
        end
      end
    end

    @search.execute

    respond_to do|format|
      format.html{
        if request.xhr?
          render :partial => 'shared/search_results/list', :object => @search, :layout => false
        else
          render
        end
      }
      format.json{ render :json => @search }
    end
  end

  def edit
  end

  def destroy
    begin
      @republished_feed = @input_source.republished_feed
      @input_source.destroy
      flash[:notice] = 'Removed that item'
    rescue
      flash[:notice] = 'Could not remove that item'
    end
    redirect_to republished_feed_url(@republished_feed)
  end

  def show
  end

  private

  def load_republished_feed
    republished_feed_id = (params[:input_source].blank?) ? params[:republished_feed_id] : params[:input_source][:republished_feed_id]
    @republished_feed = RepublishedFeed.find(republished_feed_id)
  end

  def load_input_source
    @input_source = InputSource.find(params[:id])
  end

end