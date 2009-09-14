require 'rubygems'

require 'activeresource'


class Pivotal < ActiveResource::Base

  begin
    @@pivotal_config = CampfireBot::Bot.instance.config['pivotal_tracker']
    raise if @@pivotal_config.nil?
  rescue
    raise "You need to define your site and api token in the config file under pivotal_tracker_site"
  end

  
  headers['X-TrackerToken'] = @@pivotal_config['token']

  self.site = "http://www.pivotaltracker.com/services/v2/projects/#{@@pivotal_config['project_id']}"

  def self.textilize(iteration_group='current')    
    
  
    textile = ''
    Iteration.find(:all, :params => {:project_id => @@pivotal_config['project_id'], :group => iteration_group}).each do |iteration|

      textile << "Iteration #{iteration.number}\n\n"

      textile << "{background:#ddd}. |Title|Description|Tracker|\n"

      last = iteration.stories.size - 1

      iteration.stories.each_with_index do |story, index|

        textile << "|#{story.name}|#{story.description || '&nbsp;'}|\"##{story.id}\":http://www.pivotaltracker.com/story/show/#{story.id}|\n"

        textile << "|&nbsp;|&nbsp;|&nbsp;|\n" unless last == index

      end
      textile << "\n\n"
    end
    textile
  end
  
  def self.parse(msg)

    if msg.include?('current')
      iteration_group = 'current'
    elsif msg.include?('done')
      iteration_group = 'done'
    elsif msg.include?('backlog')
      iteration_group = 'backlog'
    end

    self.textilize(iteration_group)
  end
end  
  
class Story < ActiveResource::Base

    begin
      @@pivotal_config = CampfireBot::Bot.instance.config['pivotal_tracker']
      raise if @@pivotal_config.nil?
    rescue
      raise "You need to define your site and api token in the config file under pivotal_tracker_site"
    end


    headers['X-TrackerToken'] = @@pivotal_config['token']

    self.site = "http://www.pivotaltracker.com/services/v2/projects/#{@@pivotal_config['project_id']}"
  
  def self.create_story(msg)
    requester = (msg[:message].split(",").size == 1) ? msg[:person] : msg[:message].split(",").first
    s = Story.create(:name => truncate_words(msg[:message]), :requested_by => requester, :description => msg[:message], :project_id => @@pivotal_config['project_id'])
    s.valid? ? 'Story created successfully' : "unable to create : #{s.errors.inspect}"
  end
  
  def self.truncate_words(text, length = 30, separator = ' ', truncate_string = '...')
    ' ' if text.nil? 
    truncated_text = text.split[0..length].join(separator) 
    if(truncated_text == text) 
      text 
    else 
      truncated_text + ' ' + truncate_string
    end
  end
  
end

class PivotalTracker < CampfireBot::Plugin
  on_command 'summarize', :fetch_textilize_summary
  on_command 'story', :create_story
  
  def fetch_textilize_summary(msg)
    msg.paste Pivotal.parse(msg[:message])
  end
  
  def create_story(msg)
    msg.paste Story.create_story(msg)
  end
  
end

