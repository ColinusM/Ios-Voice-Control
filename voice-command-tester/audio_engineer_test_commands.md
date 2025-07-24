# 100 Professional Audio Engineer Voice Commands Test Suite

## **Channel Control & Faders (25 commands)**

1. "Set channel 1 to unity"
2. "Bring up channel 5"
3. "Pull down track 8"
4. "Crank channel 12 to plus 3 dB"
5. "Bury channel 7"
6. "Push the vocal fader"
7. "Ride the lead guitar"
8. "Trim channel 3 to minus 10"
9. "Set track 15 to zero dB"
10. "Boost channel 2 by 6 dB"
11. "Cut channel 9 by 4 decibels"
12. "Channel 6 to minus 15"
13. "Track 11 up 2 dB"
14. "Fader 4 to plus 1"
15. "Input 7 down to minus 8"
16. "Bring track 14 to unity gain"
17. "Set the kick to plus 2 dB"
18. "Pull the snare down 3 dB"
19. "Bass channel to minus 5"
20. "Vocal track up 4 decibels"
21. "Channel 20 to nominal"
22. "Track 25 down by half"
23. "Input 13 up to hot"
24. "Set channel 18 conservative"
25. "Push track 22 a bit"

## **Muting & Solo (20 commands)**

26. "Mute channel 3"
27. "Kill channel 7"
28. "Cut track 5"
29. "Solo channel 1"
30. "Unmute channel 8"
31. "Kill the drums"
32. "Mute the bass"
33. "Solo the vocals"
34. "Cut the guitar"
35. "Kill track 12"
36. "Mute channel fifteen"
37. "Solo track eight"
38. "Cut the kick drum"
39. "Kill the snare"
40. "Mute the overhead"
41. "Solo the lead vocal"
42. "Cut background vocals"
43. "Kill the piano"
44. "Mute the strings"
45. "Solo the saxophone"

## **Routing & Sends (25 commands)**

46. "Send channel 1 to mix 3"
47. "Route track 5 to aux 2"
48. "Send the vocals to mix 1"
49. "Route channel 8 to bus 4"
50. "Send track 12 to aux seven"
51. "Patch channel 3 into wedge 2"
52. "Send the kick to drummer's mix"
53. "Route vocals to singer's wedge"
54. "Send guitar to monitor 3"
55. "Feed channel 7 to IEM mix 1"
56. "Send track 9 to in-ears"
57. "Route bass to aux 5"
58. "Send channel 14 to foldback 2"
59. "Patch track 6 into mix 8"
60. "Send the snare to wedges"
61. "Route overhead to monitors"
62. "Send track 18 to bus nine"
63. "Feed vocals to the ears"
64. "Send channel 22 to matrix 3"
65. "Route mix 2 to matrix 1"
66. "Send aux 4 to matrix out"
67. "Patch channel 11 to group 3"
68. "Route track 16 to subgroup 2"
69. "Send channel 25 to DCA 1"
70. "Feed track 19 to the wedge"

## **Panning & Positioning (15 commands)**

71. "Pan channel 1 left"
72. "Pan track 5 hard right"
73. "Center channel 8"
74. "Pan the vocals hard left"
75. "Center the kick drum"
76. "Pan guitar slight right"
77. "Hard left on the snare"
78. "Pan track 12 right"
79. "Center the bass"
80. "Pan channel 15 hard right"
81. "Spread the overheads"
82. "Pan the piano left"
83. "Center track 18"
84. "Pan vocals to the right"
85. "Hard right on guitar"

## **Effects & Processing (10 commands)**

86. "Add reverb to vocals"
87. "Send the guitar to delay"
88. "Compress the bass"
89. "Gate the snare"
90. "Add hall reverb to strings"
91. "Slapback delay on vocal"
92. "Compress the kick hard"
93. "Add plate reverb to piano"
94. "Limit the lead vocal"
95. "High-pass filter the guitar"

## **Scene & System Commands (5 commands)**

96. "Recall scene 15"
97. "Load scene 8"
98. "Go to scene twenty"
99. "Scene change 5"
100. "Recall preset 12"

---

## **Testing Instructions**

### **How to Test:**
1. **Start both systems**: Voice Command Tester (localhost:5001) + ComputerReceiver GUI
2. **For each command**:
   - Enter in Firefox GUI
   - Click "Process Command"
   - Note if RCP commands generate
   - Click "Send to Receiver" 
   - Verify message appears in ComputerReceiver
3. **Mark results**: ✅ Works / ❌ Fails / ⚠️ Partial

### **Expected Results:**
- **Channels 1-40**: Should work (validation limit)
- **Mixes/Aux 1-20**: Should work (validation limit)  
- **Word numbers**: "fifteen", "seven", "twenty" should convert properly
- **Professional terminology**: "track", "bus", "wedge", "IEM", "foldback" should work
- **Instrument names**: After labeling, "vocals", "kick", "snare" should route correctly

### **Common Failure Patterns:**
- **High channel numbers** (>40): Should show validation errors
- **Complex sentences**: May not parse correctly
- **Ambiguous commands**: May generate no RCP output
- **Multiple simultaneous actions**: May need separate commands

---

**🎯 Goal**: Achieve 80%+ success rate for professional audio engineer workflow commands.