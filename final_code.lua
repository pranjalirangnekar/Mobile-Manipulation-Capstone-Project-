
function fromCSV (s)
    s = s .. ','        -- ending comma
    local t = {}        -- table to collect fields
    local fieldstart = 1
    repeat
        local nexti = string.find(s, ',', fieldstart)
		table.insert(t, string.sub(s, fieldstart, nexti-1))
		fieldstart = nexti + 1
    until fieldstart > string.len(s)
    return t
end

function file_exists(name)
    local f = io.open(name, "r")
    if f~= nil then 
        io.close(f) 
        return true 
    else 
        return false 
    end
end

function parseCSVFile()
    local data = {}
    local out = ""
    fname = simUI.getEditValue(ui, 1001)
    if not file_exists(fname) then
	    out = string.format("Failed to parse!<br>Could not find file:<br>%s", fname)
	    simUI.setLabelText(ui, 1003, out)
	    return false
    end
    -- Now parse file into table:
    local i = 1
    local parsedLine = {}
    for line in io.lines(fname) do
        if not string.find(line, '#') and line ~= '' then
   	        local parsedLine = fromCSV(line)
	        if (#parsedLine < 12) then
                out = string.format("Error Parsing: Data line %d only has %d length)<br>Raw:<br>%s", i, #parsedLine, line)
                return false
            end
            local q={}
            for j=1, #parsedLine, 1 do
                table.insert(q, tonumber(parsedLine[j]))
                if q[j] == nil then
                    out = string.format("Failed to parse!<br>Could not convert data line %d!<br> Raw Value=%s", i, line)
                    simUI.setLabelText(ui, 1003, out)
                    return false
                end
            end
	    data[i] = q
	    i = i + 1
        end
    end
    jointData = data
    out = string.format("Successfully parsed file!<br>Filename = %s<br>Line count = %d", fname, i - 1)
    simUI.setLabelText(ui, 1003, out)
    -- write out new filename to default file:
    local fout = io.open(default_file, "w")
    fout:write(fname)
    fout:close()
    return true
end

function assignConfig(data, tinterp, dt)
    local q = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    local keyIndex = math.floor(tinterp / dt)
    if keyIndex < 1 then
        q = data[1]
        --sim.setThreadAutomaticSwitch(false)
        --sim.setJointPosition(j1, -1, 0.025) -- change the position of the model
        --sim.setJointPosition(j2, -1, -0.025) -- change the position of the model
        --sim.setThreadAutomaticSwitch(true)
    elseif keyIndex > #data + 100 then
	    sim.stopSimulation()
    elseif keyIndex > #data then
	    q = data[#data]
    else
        for i = 1, #data[1], 1 do
			q[i] = data[keyIndex][i]
		end     	 
    end
    return q
end

function playPressed(ui, id)  
    if parseCSVFile() then
    local out = nil
	startTime = sim.getSimulationTime() + 1
	playbackStatus = true
    simUI.hide(ui)
    end
end

function applyJoints(jointHandles, joints)
    for i = 1, #jointHandles, 1 do
	    sim.setJointPosition(jointHandles[i], joints[i])
    end
    if joints[13] == 0 then
        sim.setJointTargetVelocity(j2, -0.04) --opening
    else
        sim.setJointTargetVelocity(j2, 0.04) --closing
    end
    sim.setJointTargetPosition(j1, sim.getJointPosition(j2) * -1)
end

function resetPressed(ui, id)
    local out
    ob1_config = {1, 0, 0}
    ob2_config = {0, -1, -math.pi / 2}
    out = string.format("%6.2f", ob1_config[1])
    simUI.setEditValue(ui, 3001, out)
    out = string.format("%6.2f", ob1_config[2])
    simUI.setEditValue(ui, 3002, out)
    out = string.format("%6.2f", ob1_config[3])
    simUI.setEditValue(ui, 3003, out)
    out = string.format("%6.2f", ob2_config[1])
    simUI.setEditValue(ui, 3004, out)
    out = string.format("%6.2f", ob2_config[2])
    simUI.setEditValue(ui, 3005, out)
    out = string.format("%6.2f", ob2_config[3])
    simUI.setEditValue(ui, 3006, out)

    sim.resetDynamicObject(ob1)
    sim.setObjectPosition(ob1,-1, {ob1_config[1], ob1_config[2], 0.025})
    sim.setObjectOrientation(ob1,-1, {0, 0, ob1_config[3]})
    sim.resetDynamicObject(ob2)
    sim.setObjectPosition(ob2,-1, {ob2_config[1], ob2_config[2], 0.025})
    sim.setObjectOrientation(ob2,-1, {0, 0, ob2_config[3]})
end

function confirmPressed(ui, id)
    local input = {}
	for i = 1, 6, 1 do
        input[i] = simUI.getEditValue(ui, 3000 + i)
        if tonumber(input[i]) == nil then
            out = string.format("Could not parse entered configurations!")
            simUI.setLabelText(ui, 1003, out)
            resetPressed(ui, id)
            return
        end
    end
    ob1_config[1] = input[1]
    ob1_config[2] = input[2]
    ob1_config[3] = input[3]
    ob2_config[1] = input[4]
    ob2_config[2] = input[5]
    ob2_config[3] = input[6]

    sim.resetDynamicObject(ob1)
    sim.setObjectPosition(ob1,-1, {ob1_config[1], ob1_config[2], 0.025})
    sim.setObjectOrientation(ob1,-1, {0, 0, ob1_config[3]})
    sim.resetDynamicObject(ob2)
    sim.setObjectPosition(ob2,-1, {ob2_config[1], ob2_config[2], 0.025})
    sim.setObjectOrientation(ob2,-1, {0, 0, ob2_config[3]})
end

if (sim_call_type==sim.syscb_init) then
    xml = 
    [[
    <ui closeable="false" on-close="closeEventHandler" resizable="true">
        <group layout="vbox">
            <label text = "<big> Block configurations </big>" id = "9000" wordwrap = "false" style = "font-weight: bold;"/>
            <group layout = "grid">
                <label text = "Initial: "/>  
                <label text = "x (m):"/>
                <edit id = "3001" value = "1.0"/>
                <label text = "y (m):"/>
                <edit id = "3002" value = "0.0"/>
                <label text = "phi (rad):"/>
                <edit id = "3003" value = "0.0"/>  
                <button text = "Reset" onclick = "resetPressed"/>
                <br/>
                <label text = "Goal: "/>  
                <label text = "x (m):"/>
                <edit id = "3004" value = "0.0"/>
                <label text = "y (m):"/>
                <edit id = "3005" value = "-1.0"/>
                <label text = "phi (rad):"/>
                <edit id = "3006" value = "-1.57079632679"/> 
                <button text = "Confirm" onclick = "confirmPressed"/>
            </group>
            <label text="<big> Enter CSV Filename </big>" id="1000" wordwrap="false" style="font-weight: bold;"/>
            <label text="CSV column order:" />
            <label text="Chassis phi , Chassis x, Chassis y, Joint 1, Joint 2, Joint 3, Joint 4, Joint 5, Wheel 1, Wheel 2, Wheel 3, Wheel 4, Gripper state." />
            <group layout="hbox">
                <edit value="" id="1001" />
                <button text="Play File" on-click="playPressed" id="2000" />
            </group>
            <label text="<big> Messages:</big>" id="1002" wordwrap="false" style="font-weight: bold;"/>
            <group layout="vbox">
                <label value="" id="1003" wordwrap="true" />
   			</group>
        </group>
    </ui>
    ]]
	  
    ui = simUI.create(xml)
    -- get joints:
    jh = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}
    jh[2] = sim.getObjectHandle('World_X_Joint')
    jh[3] = sim.getObjectHandle('World_Y_Joint')
    jh[1] = sim.getObjectHandle('World_Th_Joint')
    for i = 4, 8, 1 do
        jh[i] = sim.getObjectHandle('Joint' .. (i - 3))
    end
    jh[9] = sim.getObjectHandle('rollingJoint_fl')
    jh[10] = sim.getObjectHandle('rollingJoint_fr')
    jh[11] = sim.getObjectHandle('rollingJoint_rr')
    jh[12] = sim.getObjectHandle('rollingJoint_rl')
    j1 = sim.getObjectHandle('youBotGripperJoint1')
    j2 = sim.getObjectHandle('youBotGripperJoint2')
    ob1 = sim.getObjectHandle('Cuboid_initial')
    ob2 = sim.getObjectHandle('Cuboid_goal')
	--allModelObjects=sim.getObjectsInTree(h) -- get all objects in the model
	--sim.setThreadAutomaticSwitch(false)
	--for i=1,#allModelObjects,1 do
        --sim.resetDynamicObject(allModelObjects[i]) -- reset all objects in the model
	--end
	--sim.setJointPosition(j1, -1, 0.025) -- change the position of the model
	--sim.setJointPosition(j2, -1, -0.025) -- change the position of the model
	--sim.setThreadAutomaticSwitch(true)
    -- constants for playback:
    ob1_config = {1, 0, 0}
    ob2_config = {0, -1, -math.pi / 2}
    jointData = nil
    fname = ""
    nominalDT = sim.getSimulationTimeStep()
    startTime = 0.0
    -- flags
    playbackStatus = false
    -- setup default filename
    default_file = ".youbot_csv_njlw_default_csv"
    if file_exists(default_file) then
        local f = io.open(default_file, "rb")
        local content = f:read("*all")
        f:close()
        simUI.setEditValue(ui, 1001, content)
        parseCSVFile(ui, 2000)
        q = assignConfig(jointData, 0, nominalDT)
        if q then
            applyJoints(jh, q)
        end
    end
end

if (sim_call_type==sim.syscb_actuation) then
    local t = 0.0
    local reset = nil
    local q = nil
    if playbackStatus then
        t = sim.getSimulationTime() - startTime
        q = assignConfig(jointData, t, nominalDT)
        if q then
            applyJoints(jh, q)
        end
    end
end

if (sim_call_type==sim.syscb_sensing) then
end

if (sim_call_type==sim.syscb_cleanup) then
   simUI.destroy(ui)
end
