using AutoMapper;

using Todo.Data.Access;
using E = Todo.Data.Entity;

namespace Todo.Data.Service.Mappings;

public class ClipboardMapper : Profile
{
    public ClipboardMapper()
    {
        CreateMap<E.Clipboard, Clipboard>();
    }
}
