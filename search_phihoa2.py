# -*- coding: utf-8 -*-
import os
for root, _, files in os.walk("E:/Tu vi online/frontend/lib"):
    for file in files:
        if file.endswith(".dart"):
            with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                content = f.read()
                if "phiHoa" in content:
                    print(file)

