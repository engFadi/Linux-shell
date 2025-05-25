addTestRecord() {

echo "Please Enter Patient ID (please enter exactly 7 digits):"
read patientID
count=$(echo -n "$patientID" | wc -c) #this line counts the number of digits in ID
while [ "$count" -ne 7 ] || ( echo "$patientID" | grep -q '[A-Za-z]')
do
echo "wrong input, please make sure that the ID has 7 digits"
read patientID
count=$(echo -n "$patientID" | wc -c) #this line counts the number of digits in ID
done


echo "Please Enter Test Name"
read name
while echo "$name" | grep -q '[0-9]' #this line checks if the name has ant number (-q search for a pattern quietly without producing output)
do
echo "Wrong input"
read name
done

echo "Please Enter Date"
read date
while ! echo "$date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}' #this line to make sure that the date like this (YYYY-MM)
do
echo "Wrong input"
read date
done

echo "Please enter result:" #need to check if the number is float
read result
while echo "$result" | grep -q '[A-Za-z]'
do
echo "Wrong input"
read result
done

echo "Please enter unit:"
read unit
while true
do
if [ "$unit" = 'g/dL' -o "$unit" = 'mg/dL' -o "$unit" = 'mm Hg' ]
then
break
else
echo "Wrong input"
read unit
fi
done

echo "Please enter status:"
read status
status=$(echo "$status" | tr '[A-Z]' '[a-z]')

while true
do
if [ "$status" = "pending" -o "$status" = "completed" -o "$status" = "reviewed" ]
then
break
else
echo "Invalid Status. Must be one of: Pending, Completed, Reviewed."
read status
status=$(echo "$status" | tr '[A-Z]' '[a-z]')
fi
done

echo "$patientID: $name, $date, $result, $unit, $status" >> $"medicalRecord.txt"
echo "successful"


}

################################################################################################################
searchByPatientId() {
echo "Please Enter Patient ID (please enter exactly 7 digits):"
read patient_id
count=$(echo -n "$patient_id" | wc -c) #this line counts the number of digits in ID
while [ "$count" -ne 7 ] || ( echo "$patientID" | grep -q '[A-Za-z]')
do
echo "wrong input, please make sure that the ID has 7 digits"
read patient_id
count=$(echo -n "$patient_id" | wc -c) #this line counts the number of digits in ID
done

echo "1. Retrieve all patient tests"
echo "2. Retrieve all abnormal patient tests"
echo "3. Retrieve all patient tests in a specific period"
echo "4. Retrieve all patient tests based on test status"
echo -n "Enter your choice [1-4]:"
read option

case $option in
1)
grep "^$patient_id:" medicalRecord.txt
;;
2)
grep "^$patient_id" medicalRecord.txt | while read line; do
test_name=$(echo "$line" | cut -d',' -f1 | cut -d' ' -f2) #save test name from record file in test_name var

result=$(echo "$line" | cut -d',' -f3 | cut -d' ' -f2 ) #save specific result to result var
grep "$test_name" medicalTest.txt | while read line1; do
normal_range=$(echo "$line1" |cut -d';' -f2 | cut -d':' -f2) #take the test result range from test file
count=$(echo -n "$normal_range" | wc -w) #count if the range is two number or one

if [ $count -eq "2" ]
then
range=$(echo "$normal_range" | cut -d',' -f1 | cut -d'<' -f2 | tr -d ' ')
if [ $result -lt $range ]
then
echo "normal: $line"
else
:
fi

else
min_range=$(echo "$normal_range" | cut -d',' -f1 | cut -d'>' -f2 | tr -d ' ' ) #save min range
max_range=$(echo "$normal_range" | cut -d',' -f2 | cut -d'<' -f2 | tr -d ' ' ) #save max range

is_within_range=$(echo "$result > $min_range && $result < $max_range" | bc)

if [ $is_within_range -eq "1" ]
then
echo "normal :$line"
else
:
fi
fi

done
done
;;

3)
echo "Enter Start Date (YYYY-MM):"
read start_date

echo "Enter End Date (YYYY-MM):"
read end_date

# Validate date format (simple check)
if ! echo $start_date | grep -q '^[0-9]\{4\}-[0-9]\{2\}' || ! echo $start_date | grep -q '^[0-9]\{4\}-[0-9]\{2\}'
then
echo "Invalid date format. Please use YYYY-MM."
fi

# Ensure start date is not greater than end date
if [[ "$start_date" > "$end_date" ]]
then
echo "Start date cannot be greater than end date."
fi
# Loop through the medical record file and check the date
grep "$patient_id" $"medicalRecord.txt" | while read -r line
do
# Extract the patient ID, date, and the rest of the line

test_date=$(echo "$line" | cut -d',' -f2 | tr -d ' ')
# Check if the line belongs to the given patient ID

# Compare dates and print if within the range
if [[ ("$test_date" > "$start_date" || "$test_date" == "$start_date") && ("$test_date" < "$end_date" || "$test_date" > "$end_date") ]]

then
echo "$line"
fi

done
;;

4)
echo -n "Enter status (pending, completed, reviewed):"
read status
status=$(echo "$status" | tr '[A-Z]' '[a-z]')
while true; do
if [ "$status" = "pending" ] || [ "$status" = "completed" ] || [ "$status" = "reviewed" ]; then
break
else
echo "Invalid Status. Must be one of: pending, completed, reviewed."
read status
status=$(echo "$status" | tr '[A-Z]' '[a-z]')
fi
done
grep "^$patient_id:" medicalRecord.txt | grep "$status"
;;
*)
echo "Invalid option."
;;
esac
}
################################################################################################################
updateTestResult() {
echo "please enter patient ID"
read patientID
count=$(echo -n "$patientID" | wc -c) # this line counts the number of digits in ID

while [ "$count" -ne 7 ] || echo "$patientID" | grep -q '[^0-9]'; do
echo "wrong input, please make sure that the ID has 7 digits"
read patientID
count=$(echo -n "$patientID" | wc -c) # this line counts the number of digits in ID
done

echo "Please Enter Test Name"
read name

# Loop to check if the name contains any numbers
while echo "$name" | grep -q '[0-9]'; do
echo "Wrong input"
read name
done


echo "Please Enter Date"
read date
while ! echo "$date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}' #this line to make sure that the date like this (YYYY-MM)
do
echo "Wrong input"
read date
done

# Extract the specific line from the file
temp=$(sed -n "/$patientID: $name, $date/p" medicalRecord.txt)

# Check if the record was found
if [ -z "$temp" ]; then
echo "No record found for Patient ID: $patientID and Test Name: $name."
return
fi

# Remove the line from the file and save to a temporary file
sed "/$patientID: $name, $date/d" medicalRecord.txt > tempFile.txt

# Replace the old result with the new one in the variable `temp`
echo "Please enter a new result:"
read result

# Loop to check if the result contains only numbers
while echo "$result" | grep -q '[A-Za-z]'; do
echo "Wrong input"
read result
done

temp2=$(echo "$temp" | cut -d' ' -f4)
temp=$(echo "$temp" | sed "s/$temp2/$result,/")

# Append the modified line to the temporary file
echo "$temp" >> tempFile.txt

# Move the temporary file back to the original file
mv tempFile.txt medicalRecord.txt

echo "Record updated successfully."
}
################################################################################################################
searchNormalTests(){
echo "Please Enter Test Name"
read name
while echo "$name" | grep -q '[0-9]' #this line checks if the name has ant number (-q search for a pattern quietly without producing output)
do
echo "Wrong input"
read name
done
grep "$name" medicalRecord.txt | while read line; do
test_name=$(echo "$line" | cut -d',' -f1 | cut -d' ' -f2) #save test name from recored file ro test_name var

result=$(echo "$line" | cut -d',' -f3 | cut -d' ' -f2 ) #save spicific result to result var
grep "$test_name" medicalTest.txt | while read line1; do
normal_range=$(echo "$line1" |cut -d';' -f2 | cut -d':' -f2) #take the test result range from test file
count=$(echo -n "$normal_range" | wc -w) #count if the range is two number or one

if [ $count -eq "2" ]
then
range=$(echo "$normal_range" | cut -d',' -f1 | cut -d'<' -f2 | tr -d ' ')
if [ $result -le $range ]
then
echo "normal: $line"
else
:
fi

else
min_range=$(echo "$normal_range" | cut -d',' -f1 | cut -d'>' -f2 | tr -d ' ' ) #save min range
max_range=$(echo "$normal_range" | cut -d',' -f2 | cut -d'<' -f2 | tr -d ' ' ) #save max range

is_within_range=$(echo "$result >= $min_range && $result <= $max_range" | bc)

if [ $is_within_range -eq "1" ]
then
echo "nromal :$line"
else
:
fi
fi

done
done
if [ -z $is_within_range ]
then
echo "not found!"
fi

}
###############################################################################################################
retrieveAverageTestValues() {
echo "Please Enter Test Name"
read name
while echo "$name" | grep -q '[0-9]'; do
echo "Wrong input"
read name
done

temp=$(grep "$name" medicalRecord.txt | sed 's/,//g')
if [ -z "$temp" ]; then
echo "No record found for Test Name: $name."
return
fi

sum=0
count=0
temp2=$(echo "$temp" | cut -d' ' -f4)

for value in $temp2; do
sum=$(echo "$sum + $value" | bc)
count=$((count + 1))
done
# Check if the record was found
if [ $count -eq 0 ]; then
echo "No values found for Test Name: $name."
return
fi

average=$(echo "scale=2; $sum / $count" | bc)
echo "Average = $average"
}
################################################################################################################

# Function to display the menu
show_menu() {
echo "Medical Record Management System"
echo "1. Add a new medical test record"
echo "2. Search for tests by patient ID"
echo "3. Update an existing test result"
echo "4. Retrieve average test values"
echo "5. Searching for up normal tests"
echo "6. Exit"
echo -n "Enter your choice [1-6]: "
}

# Main loop
while true; do
show_menu
read choice
case $choice in
1) addTestRecord ;;
2) searchByPatientId ;;
3) updateTestResult ;;
4) retrieveAverageTestValues ;;
5) searchNormalTests ;;
6) exit 0 ;;
*) echo "Invalid choice. Please enter a number between 1 and 6." ;;
esac
done