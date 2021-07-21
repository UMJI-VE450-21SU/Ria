SECTIONS
{
    . = 0;
    .text : {
        * (.start);
        * (.text);
    }
    .data : {
        * (.data);
    }
    . = 0x80000000;
    .comment : {
        * (.comment);
    }
    .note.gnu.build-id : {
        * (.note.gnu.build-id);
    }
}
