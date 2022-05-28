*** Settings ***
Documentation   Robot created to automate the process of ordering multiple robot orders.
Library         RPA.Browser
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.HTTP
Task Teardown   Close All Browsers

*** Keywords ***
Read CSV
    ${order_file}=    Set Variable    orders.csv
    Download    https://robotsparebinindustries.com/${order_file}    overwrite=True
    ${orders}=    Read Table From Csv    ${order_file}
    [Return]    ${orders}

*** Keywords ***
Filling form for each order
    [Arguments]    ${robot}
    ${head_as_string}=          Convert To String    ${robot}[Head]
    Select From List By Value   head                 ${head_as_string}
    ${radio_as_string}=         Convert To String    ${robot}[Body]
    Select Radio Button         body                 ${radio_as_string}
    ${legs_as_string}=          Convert To String    ${robot}[Legs]
    Input Text                  class:form-control   ${legs_as_string} 
    ${address_as_string}=       Convert To String    ${robot}[Address]
    Input Text                  address              ${address_as_string}

*** Keywords ***
Save Reciept as PDF
    [Arguments]         ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=             Set Variable    ${CURDIR}${/}Reciepts${/}robot-${order_number}.pdf
    Html To Pdf         ${receipt_html}    ${pdf}
    [Return]            ${pdf}
Screenshot of the robot
    [Arguments]         ${order_number}
    ${screenshot}=      Set Variable    ${CURDIR}${/}Reciepts${/}robot-${order_number}.png
    Screenshot          id:robot-preview-image    ${screenshot}
    [Return]            ${screenshot}
Merge the reciept and PDF
    [Arguments]         ${screenshot}    ${pdf}
    Open Pdf Document   ${pdf}
    Add Image To Pdf    ${screenshot}    target=${pdf}
    Close Pdf Document  ${pdf}


*** Keywords ***
Login
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order
Preview Robot
    Click Button            preview   
Order Robot
    Click Button            id:order  
    Wait Until Element Is Visible    id:receipt
Order new Robot
    [Arguments]                                      ${order}
    ${pdf}=           Save Reciept as PDF            ${order}[Order number]
    ${screenshot}=    Screenshot of the robot        ${order}[Order number]
    Merge the reciept and PDF       ${screenshot}    ${pdf}
    Wait Until Element Is Visible   id:order-another
    Click Button                    id:order-another

*** Keywords ***
Creat ZIP File
    Archive Folder With Zip    ${CURDIR}${/}Reciepts${/}    ${CURDIR}${/}orders.zip

*** Tasks ***
Order the Robots using CSV
    ${orders}=     Read CSV
    Login
    FOR    ${ord}    IN    @{orders}
        Click Button                   class:btn-dark
        Filling form for each order    ${ord}
        Preview Robot     
        Wait Until Keyword Succeeds    5x    1s    Order Robot
        Order new Robot                ${ord}
    END
    Creat ZIP File
