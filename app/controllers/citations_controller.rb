require 'citation'

class CitationsController < ApplicationController

  def set_rating
    c = Citation.find(params[:id])
    c.rating = params[:rating]
    c.save!
    render :nothing => true
  end

  def index
    render :action => 'parse_string'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    redirect_to :action => "show"
  end

  def api_instructions
  end

  def create
    unless params[:citation]
      render :text => "Citation text is missing", :status => :bad_request
      return
    end

    if params["commit"]
      cstrs = params[:citation][:string].split(/\n+/).compact
    else
      cstrs = listify(params[:citation])
    end
    cstrs.reject! {|str| str.strip.empty?}

    @citations = []

    status = true
    cstrs.each {|cstr|
      citation = Citation.create_from_string(cstr)
      status &= citation.save
      @citations << citation
    }

    if status
      respond_to do |wants|
        wants.html {
          if @citations.empty?
            redirect_to :action => 'parse_string'
          else
            redirect_to :action => 'show', :citations => @citations
          end
         }
         wants.js 
         wants.xml { 
           render :xml => 
             "<citations>\n" << citations2xml(@citations) << "</citations>\n",
           :status => :ok
         }
      end
    else
      render :text => "Error creating citations: #{cstrs.join("\n")}",
             :status => :internal_server_error
    end
  end

  def show
    if params[:citations]
      @citations = params[:citations].map {|c| Citation.find c.to_i}
    else
      @citations = Citation.find :all
    end
  end

  private
  def listify(es)
    es ||= []
    es = [es] unless Array === es
    return es
  end
  def citations2xml(citations)
    citations.map{|c| "#{c.to_xml}\n#{c.context_object.xml}"}.join("\n")
  end
end

