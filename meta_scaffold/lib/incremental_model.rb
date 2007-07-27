
# Returns a struct with the changes needed to reflect
# new classes 
def changes_to_apply(db_klasses, new_klasses)
  klasses_final = {}
  new_klasses.each_pair do |klass, attr|
    klasses_final[klass] = if db_klasses[klass]
      table_modifications_for(db_klasses[klass], attr) 
      else; attr; end    
  end
  klasses_final
end

# gets the table modifications needed for convert the model from
# old_attr to new_attr
def table_modifications_for(old_attr, new_attr)
  old_fields = old_attr[:class_attr]
  new_fields = new_attr[:class_attr]
  
  modify = {}; add = {}; remove = []
  
  old_fields.keys.each do |old_field|
    remove << old_field unless new_fields && new_fields.keys.include?(old_field)
    modify[old_field] = new_fields[old_field] if new_fields && old_fields && (old_fields[old_field] != new_fields[old_field])
  end if old_fields
  new_fields.keys.each do |new_field|
    add[new_field] = new_fields[new_field] unless old_fields && old_fields.keys.include?(new_field)
  end if new_fields
  
  ret_attr = {}
  ret_attr[:modify] = modify unless modify.empty?
  ret_attr[:add] = add unless add.empty?  
  ret_attr[:remove] = remove.sort unless remove.empty?  
  
  return ret_attr
end

