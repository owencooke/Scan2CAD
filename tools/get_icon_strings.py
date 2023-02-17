import os

basedir = os.path.dirname(__file__)
dir = "../assets/icons"

with open(os.path.join(basedir,"icons.txt"), "w") as fout:
    for f in os.listdir(os.path.join(basedir,dir)):
        icon_name = f.split("solid")[0]
        icon_name = icon_name[:len(icon_name)-1]
        icon_name = icon_name.replace("-", "_")
        
        fout.write("readonly property string " + icon_name + ": \"file:assets/icons/" + f + "\"")
        fout.write('\n')
    