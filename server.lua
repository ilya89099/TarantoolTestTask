
function get_suff(str) 
    if (str == nil) then
        return nil
    end
    local start, finish = string.find(str, "/[^/]*$")
    return string.sub(str, start + 1, finish)
end



handler_collection = {
    post = function(req)
        local body = req:json()
        if (body.key == nil or body.value == nil) then
            return {status = 400}
        end
        if (kv_storage:insert(body.key, json.encode(body.value))) then
            return {status = 200}
        else
            return {status = 409}
        end
    end,
    
    put = function(req)
        local key = get_suff(req:path())
        local body = req:json()
        if (body.value == nil or #key == 0) then
            return {status = 400}
        end
        if (kv_storage:update(key, json.encode(body.value))) then
            return {status = 200}
        else
            return {status = 404}
        end
        
    end,
   
    delete = function(req)
        key = get_suff(req:path())
        if (#key == 0) then
            return {status = 400}
        end
        if (kv_storage:delete(key)) then
            return {status = 200} 
        else
            return {status = 404}   
        end
    end,

    get = function(req)
        key = get_suff(req:path())
        if (#key == 0) then
            return {status = 400}
        end
        if (kv_storage:has_key(key)) then
            return {status = 200, body = kv_storage:get_value(key)}
        else
            return {status  = 404}
        end
    end
}


box.cfg()
box.once("setup", function() 
    s = box.schema.space.create("storage")
    box.schema.sequence.create("AutoIncr")
    s:format({{name = "id", type = "unsigned"}, {name = "key", type = "string"}, {name = "value", type = "string"}})
    s:create_index("primary", {
        sequence = "AutoIncr",
        type = "hash",
        parts = {"id"}
    })
    s:create_index("kv_index", {
        type = "hash",
        parts = {"key"}
    })
    end
)

kv_storage = {
    s = nil,
    index = nil,

    set_storage = function(self, storage)
        self.s = storage
        self.index = storage.index.kv_index
    end,
    
    has_key = function(self, key)
        return #(self.index:select(key)) ~= 0  
    end,

    insert = function(self, key, value)
        if (self:has_key(key)) then
            return false
        end
        self.s:insert{nil, key, value}
        return true
    end,

    get_value = function(self, key, value)
        return self.index:select(key)[1]["value"]
    end,

    delete = function(self, key)
        if (not self:has_key(key)) then
            return false
        end
        self.s:delete(self.index:select(key)[1]["id"])
        return true
    end,

    update = function(self, key, value) 
        if (not self:has_key(key)) then
            return false
        end
        self.s:update(self.index:select(key)[1]["id"], {{'=', 3, value}})
        return true
    end
}

kv_storage.__index = kv_storage
kv_storage:set_storage(box.space.storage)

server = require("http.server").new(nil, 80) 
router = require("http.router").new({charset = "application/json"})
json = require("json")

server:set_router(router)
router:route({path = "/kv", method = "POST"}, handler_collection.post)
router:route({path = "/kv/.*", method = "PUT"}, handler_collection.put)
router:route({path = "/kv/.*", method = "DELETE"}, handler_collection.delete)
router:route({path = "/kv/.*", method = "GET"}, handler_collection.get)
server:start()
