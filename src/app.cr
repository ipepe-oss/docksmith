require "json"
require "ecr"
require "kemal"

DOCKER_HOST = ENV.fetch("DOCKER_HOST", "unix:///var/run/docker.sock").to_s
DOCKER_CLIENT = if DOCKER_HOST.starts_with?("unix://")
    unix = UNIXSocket.new(DOCKER_HOST.sub(/^unix:\/\//, ""))
    client = HTTP::Client.new(unix, "", 80)
  else
    uri = URI.parse(DOCKER_HOST)
    client = HTTP::Client.new(uri.host.not_nil!, uri.port.not_nil!, false)
  end

def text_to_html(text)
  text.gsub("\n", "<br>").gsub(" ", "&nbsp;").gsub("\t", "&nbsp;&nbsp;&nbsp;&nbsp;")
end

get "/" do |env|
  env.redirect "/containers"
end

get "/containers" do |env|
  json = DOCKER_CLIENT.get("/containers/json?all=true").body
  containers = JSON.parse(json).as_a
  render "src/views/containers.ecr"
end

get "/containers/:id" do |env|
  id = env.params.url["id"]
  json = DOCKER_CLIENT.get("/containers/json?id=#{id}").body
  containers = JSON.parse(json)
  container = containers[0]
  render "src/views/container.ecr"
end

get "/containers/:id/logs" do |env|
  id = env.params.url["id"]
  tail_lines = (env.params.url["tail_lines"]? || 30).to_i
  text_to_html(
    DOCKER_CLIENT.get("/containers/#{id}/logs?stdout=1&stderr=1&tail=#{tail_lines}").body
  )
end

post "/containers/:id/execute" do |env|
  id = env.params.url["id"]
  command = env.params.body["command"]
  exec_json = DOCKER_CLIENT.post(
    "/containers/#{id}/exec",
    HTTP::Headers.new.tap { |h| h["Content-Type"] = "application/json" },
    { "AttachStdout" => true, "AttachStderr" => true, "Cmd" => command.split(" ") }.to_json
  ).body
  exec_id = JSON.parse(exec_json)["Id"]
  text_to_html(
    DOCKER_CLIENT.post(
      "/exec/#{exec_id}/start",
      HTTP::Headers.new.tap { |h| h["Content-Type"] = "application/json" },
      { "Detach" => false, "Tty" => false }.to_json
    ).body
  )
end

Kemal.run
