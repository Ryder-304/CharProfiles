local addonName, ns = ...

ns.UI = ns.UI or {}
local UI = ns.UI

local function label(parent, text, x, y, width)
  local font = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  font:SetPoint("TOPLEFT", x, y)
  if width then font:SetWidth(width) end
  font:SetJustifyH("LEFT")
  font:SetText(text)
  return font
end

local function button(parent, text, x, y, width, handler)
  local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  control:SetSize(width, 22)
  control:SetPoint("TOPLEFT", x, y)
  control:SetText(text)
  control:SetScript("OnClick", handler)
  return control
end

local function edit(parent, x, y, width, height, multiline)
  local control = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  control:SetAutoFocus(false)
  control:SetSize(width, height)
  control:SetPoint("TOPLEFT", x, y)
  control:SetMultiLine(multiline and true or false)
  control:SetMaxLetters(multiline and 0 or 60)
  control:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  control:SetScript("OnEnterPressed", function(self) if not multiline then self:ClearFocus() end end)
  return control
end

local function currentProfile()
  return ns.Service and ns.Service.store:getProfile(UI.selectedId)
end

function UI:setStatus(text)
  if self.status then self.status:SetText(text or "") end
end

function UI:toggle()
  if not self.frame then self:initialize() end
  if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:refresh() end
end

function UI:refresh()
  if not self.frame or not ns.Service then return end
  local identity = ns.Service:identity()
  if not identity then self:setStatus("Charakterdaten sind noch nicht verfügbar.") return end
  self.character:SetText(identity.name .. " – " .. identity.realm)
  local profiles = ns.Service.store:listForCharacter(identity.key)
  if self.selectedId and not ns.Service.store:getProfile(self.selectedId) then self.selectedId = nil end
  if not self.selectedId and profiles[1] then self.selectedId = profiles[1].id end
  local default = ns.Service.store:defaultForCharacter(identity.key)
  for index, row in ipairs(self.rows) do
    local profile = profiles[index]
    if profile then
      row.profileId = profile.id
      row:SetText((profile.id == self.selectedId and "> " or "  ") .. profile.name .. (default and default.id == profile.id and "  [Standard]" or ""))
      row:Show()
    else
      row.profileId = nil
      row:Hide()
    end
  end
  self.name:SetText(currentProfile() and currentProfile().name or "")
end

function UI:afterAction(result, errorMessage)
  if not result then self:setStatus(errorMessage or "Aktion fehlgeschlagen") else
    self:setStatus(result.message or "Gespeichert")
    self:refresh()
  end
end

function UI:createAndCapture()
  local profile, errorMessage = ns.Service:create(self.name:GetText())
  if not profile then return self:setStatus(errorMessage) end
  self.selectedId = profile.id
  local captured, captureMessage = ns.Service:capture(profile.id)
  if not captured then return self:setStatus(captureMessage) end
  self:setStatus("Neues Profil mit aktuellem Zustand gespeichert.")
  self:refresh()
end

function UI:updateSelected()
  local profile = currentProfile()
  if not profile then return self:setStatus("Bitte zuerst ein Profil auswählen.") end
  StaticPopup_Show("CHARPROFILES_CONFIRM_OVERWRITE", profile.name, nil, profile.id)
end

function UI:loadSelected()
  local profile = currentProfile()
  if not profile then return self:setStatus("Bitte zuerst ein Profil auswählen.") end
  StaticPopup_Show("CHARPROFILES_CONFIRM_LOAD", profile.name, nil, profile.id)
end

function UI:renameSelected()
  local profile = currentProfile()
  if not profile then return self:setStatus("Bitte zuerst ein Profil auswählen.") end
  local saved, errorMessage = ns.Service:rename(profile.id, self.name:GetText())
  if not saved then return self:setStatus(errorMessage) end
  self:setStatus("Profil umbenannt.")
  self:refresh()
end

function UI:duplicateSelected()
  local profile = currentProfile()
  if not profile then return self:setStatus("Bitte zuerst ein Profil auswählen.") end
  local copy, errorMessage = ns.Service:duplicate(profile.id, self.name:GetText())
  if not copy then return self:setStatus(errorMessage) end
  self.selectedId = copy.id
  self:setStatus("Profil dupliziert.")
  self:refresh()
end

function UI:setDefault()
  local profile = currentProfile()
  if not profile then return self:setStatus("Bitte zuerst ein Profil auswählen.") end
  local saved, errorMessage = ns.Service.store:setDefault(profile.character.key, profile.id)
  self:setStatus(saved and "Standardprofil gesetzt." or errorMessage)
  self:refresh()
end

function UI:openExport(all)
  local code, errorMessage = all and ns.Service:exportAll() or ns.Service:exportOne(self.selectedId)
  if not code then return self:setStatus(errorMessage) end
  local parts, partError = ns.Codec.split(code)
  if not parts then return self:setStatus(partError) end
  self.transferTitle:SetText(all and "Alle Profile exportieren" or "Profil exportieren")
  self.transferEdit:SetText(table.concat(parts, "\n"))
  self.transferEdit:HighlightText()
  self.transferPreview:SetText(#parts > 1 and (#parts .. " Teile – alle Teile gemeinsam kopieren.") or "Code kopieren und auf dem Zielclient importieren.")
  self.importKeep:Hide(); self.importReplace:Hide(); self.importCopy:Hide(); self.previewButton:Hide()
  self.transfer:Show()
end

function UI:openImport()
  self.transferTitle:SetText("Profile importieren")
  self.transferEdit:SetText("")
  self.transferPreview:SetText("Code einfügen und anschließend prüfen.")
  self.previewButton:Show(); self.importKeep:Hide(); self.importReplace:Hide(); self.importCopy:Hide()
  self.transfer:Show()
end

function UI:previewImport()
  local inspection, errorMessage = ns.Service:inspectImport(self.transferEdit:GetText())
  if not inspection then
    self.transferPreview:SetText("Fehler: " .. errorMessage)
    self.importKeep:Hide(); self.importReplace:Hide(); self.importCopy:Hide()
    return
  end
  self.pendingInspection = inspection
  local origin = inspection.payload.origin or {}
  local warnings = 0
  for _ in pairs(inspection.unsupported) do warnings = warnings + 1 end
  self.transferPreview:SetText(string.format("%d Profile | Herkunft: %s / Build %s | Konflikte: %d | Einschränkungen: %d",
    #inspection.payload.profiles, tostring(origin.id or "unbekannt"), tostring(origin.build or "unbekannt"), #inspection.conflicts, warnings))
  self.importKeep:Show(); self.importReplace:Show(); self.importCopy:Show()
end

function UI:finishImport(policy)
  local result, errorMessage = ns.Service:import(self.transferEdit:GetText(), policy)
  if not result then return self:setStatus(errorMessage) end
  self.transfer:Hide()
  self:setStatus(string.format("Import abgeschlossen: %d Profile, %d Konflikte beibehalten.", #result.imported, #result.conflicts))
  self:refresh()
end

function UI:initialize()
  if self.frame then return end
  local frame = CreateFrame("Frame", "CharProfilesFrame", UIParent, "BackdropTemplate")
  frame:SetSize(520, 420)
  frame:SetPoint("CENTER")
  frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  frame:Hide()
  self.frame = frame
  label(frame, "CharProfiles", 18, -16, 250):SetFontObject(GameFontHighlightLarge)
  self.character = label(frame, "", 18, -43, 300)
  button(frame, "Schließen", 420, -15, 82, function() frame:Hide() end)
  label(frame, "Profile", 18, -72, 200)
  self.rows = {}
  for index = 1, 10 do
    local row = button(frame, "", 18, -76 - index * 24, 250, function(control)
      self.selectedId = control.profileId
      self:refresh()
    end)
    row:SetText("")
    self.rows[index] = row
  end
  label(frame, "Profilname", 286, -72, 180)
  self.name = edit(frame, 286, -91, 210, 22, false)
  button(frame, "Neu erfassen", 286, -122, 102, function() self:createAndCapture() end)
  button(frame, "Aktualisieren", 394, -122, 102, function() self:updateSelected() end)
  button(frame, "Laden", 286, -150, 102, function() self:loadSelected() end)
  button(frame, "Umbenennen", 394, -150, 102, function() self:renameSelected() end)
  button(frame, "Duplizieren", 286, -178, 102, function() self:duplicateSelected() end)
  button(frame, "Als Standard", 394, -178, 102, function() self:setDefault() end)
  button(frame, "Löschen", 286, -206, 102, function()
    local profile = currentProfile()
    if profile then StaticPopup_Show("CHARPROFILES_CONFIRM_DELETE", profile.name, nil, profile.id) else self:setStatus("Bitte zuerst ein Profil auswählen.") end
  end)
  button(frame, "Sicherung", 394, -206, 102, function()
    local backup, errorMessage = ns.Service:backupCurrent("Manuelle Sicherung")
    self:setStatus(backup and "Manuelle Sicherung erstellt." or errorMessage)
  end)
  button(frame, "Profil exportieren", 286, -244, 210, function() self:openExport(false) end)
  button(frame, "Alle exportieren", 286, -272, 102, function() self:openExport(true) end)
  button(frame, "Importieren", 394, -272, 102, function() self:openImport() end)
  self.status = label(frame, "", 18, -340, 475)
  self.status:SetTextColor(1, 0.82, 0)

  local transfer = CreateFrame("Frame", "CharProfilesTransferFrame", UIParent, "BackdropTemplate")
  transfer:SetSize(620, 380); transfer:SetPoint("CENTER")
  transfer:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  transfer:EnableMouse(true); transfer:Hide()
  self.transfer = transfer
  self.transferTitle = label(transfer, "", 18, -15, 400); self.transferTitle:SetFontObject(GameFontHighlightLarge)
  button(transfer, "Schließen", 520, -15, 82, function() transfer:Hide() end)
  self.transferEdit = edit(transfer, 20, -48, 580, 235, true)
  self.transferEdit:SetFontObject(ChatFontNormal)
  self.transferPreview = label(transfer, "", 20, -292, 575)
  self.previewButton = button(transfer, "Prüfen", 20, -325, 100, function() self:previewImport() end)
  self.importKeep = button(transfer, "Behalten", 140, -325, 110, function() self:finishImport("keep") end)
  self.importReplace = button(transfer, "Ersetzen", 260, -325, 110, function() self:finishImport("replace") end)
  self.importCopy = button(transfer, "Als Kopie", 380, -325, 110, function() self:finishImport("copy") end)
  self.importKeep:Hide(); self.importReplace:Hide(); self.importCopy:Hide()

  StaticPopupDialogs["CHARPROFILES_CONFIRM_OVERWRITE"] = {
    text = "Aktuellen Zustand in '%s' speichern? Die bisherigen Profildaten werden durch eine Sicherung abgesichert.", button1 = ACCEPT, button2 = CANCEL, timeout = 0, whileDead = true, hideOnEscape = true,
    OnAccept = function(_, id) local result, err = ns.Service:capture(id); UI:afterAction(result and { message = "Profil aktualisiert." }, err) end,
  }
  StaticPopupDialogs["CHARPROFILES_CONFIRM_LOAD"] = {
    text = "'%s' laden? Der aktuelle Zustand wird vorher gesichert.", button1 = ACCEPT, button2 = CANCEL, timeout = 0, whileDead = true, hideOnEscape = true,
    OnAccept = function(_, id) local result, err = ns.Service:load(id, true); UI:afterAction(result, err) end,
  }
  StaticPopupDialogs["CHARPROFILES_CONFIRM_DELETE"] = {
    text = "Profil '%s' endgültig löschen?", button1 = DELETE, button2 = CANCEL, timeout = 0, whileDead = true, hideOnEscape = true,
    OnAccept = function(_, id) local result, err = ns.Service.store:deleteProfile(id); UI:afterAction(result and { message = "Profil gelöscht." }, err) end,
  }
end
