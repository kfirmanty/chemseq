local helpers = {}

function helpers.rand_int(min, max)
    return math.floor(math.random(min, max))
 end

function helpers.obj_keys (obj)
    local keys = {}
    for key,value in pairs(obj) do
       table.insert(keys, key)
    end
    return keys
 end
 
function helpers.rand_from_obj(obj)
    local keys = helpers.obj_keys(obj)
    return keys[math.random(1, #keys)]
 end

 function helpers.rand_from_arr(arr)
    return arr[math.random(1, #arr)]
 end
 
function helpers.rand_or_empty(t)
    local should_return = math.random(1, 3) > 1
    return should_return and t[math.random(1, #t)] or ""
 end

 function helpers.shallow_merge(obj1, obj2)
    for k,v in pairs(obj2) do obj1[k] = v end
    return obj1
 end
 
 return helpers