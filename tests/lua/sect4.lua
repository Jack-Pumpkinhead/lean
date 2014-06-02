local env = environment()
env = env:begin_section_scope()
env = env:add_global_level("l")
local l = mk_global_univ("l")
env = env:add(check(env, mk_var_decl("A", mk_sort(l))), binder_info(true))
env = env:add(check(env, mk_var_decl("B", mk_sort(l))), binder_info(true))
local A = Const("A")
local list = Const("list")
env = add_inductive(env,
                    "list", mk_sort(max_univ(l, 1)),
                    "nil", list,
                    "cons", mk_arrow(A, list, list))
print(env:find("list_rec"):type())
assert(env:find("cons"):type() == mk_arrow(A, list, list))
env = env:end_scope()
print(env:find("list_rec"):type())
print(env:find("cons"):type())

local l = mk_param_univ("l")
local A = Local("A", mk_sort(l))
local list = Const("list", {l})
assert(env:find("cons"):type() == Pi({A}, mk_arrow(A, list(A), list(A))))
