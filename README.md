利用ngx.timer.at来实现定时扫描文件来获取更新
nginx.conf的配置如下
http {
    ...
    # 在worker进程启动时开启check.lua中的功能
    init_worker_by_lua_file	'conf/cop/check.lua';

    # 为check.lua中需要的共享内存区分配大小，大小为10m。
    lua_shared_dict	my_cache	10m;

    ...
}

location /access {
    content_by_lua	'
        local args = ngx.req.get_uri_args()
        local my_cache = ngx.shared.my_cache
        local value, flags = my_cache:get(args["ip"])
        if not value then
            ngx.say("ip not exist: ", args["ip"])
        else
            ngx.say("true: ", value)
        end
    ';
}

在服务器上访问该location
curl localhost/access?ip=10.25.10.10       ==>  ip not exist: 10.25.10.10

当在/home/nginx/conf/cop/下修改ip.txt，添加10.25.10.10之后访问（10秒后）
curl localhost/access?ip=10.25.10.10       ==>  true: 10.25.10.10
